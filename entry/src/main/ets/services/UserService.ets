// 用户服务层
// 负责注册、登录、密码找回、会话管理（基于 AppStorage 持久化登录态）

import { relationalStore } from '@kit.ArkData';
import { RdbHelper } from './RdbHelper';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'UserService';
const DOMAIN: number = 0x0000;

// 用户数据库实体
export interface UserEntity {
  id: number;
  username: string;
  password: string;
  nickname: string;
  phone: string;
  email: string;
  avatar: string;
  isVip: boolean;
  createdAt: string;
  updatedAt: string;
}

class UserServiceClass {
  // 注册
  async register(username: string, password: string, nickname?: string): Promise<number> {
    hilog.info(DOMAIN, TAG, `Registering user: ${username}`);

    // 检查用户名是否已存在
    const existing = await this.findByUsername(username);
    if (existing) {
      throw new Error('用户名已存在');
    }

    const now = new Date().toISOString();
    const values: relationalStore.ValuesBucket = {
      'username': username,
      'password': password,
      'nickname': nickname || username,
      'phone': '',
      'email': '',
      'avatar': '',
      'is_vip': 0,
      'created_at': now,
      'updated_at': now
    };

    hilog.info(DOMAIN, TAG, `Inserting user with values: username=${username}, nickname=${nickname || username}`);

    // insert 返回的 rowId 就是 AUTOINCREMENT 主键值，直接使用即可
    const rowId = await RdbHelper.insert('user_info', values);
    hilog.info(DOMAIN, TAG, `Insert returned rowId=${rowId}`);

    if (rowId < 0) {
      throw new Error('注册失败：数据库插入失败');
    }

    hilog.info(DOMAIN, TAG, `User registered successfully: ${username}, id=${rowId}`);
    return rowId;
  }

  // 登录
  async login(username: string, password: string): Promise<UserEntity> {
    hilog.info(DOMAIN, TAG, `Login attempt: ${username}`);

    const user = await this.findByUsername(username);
    if (!user) {
      throw new Error('用户不存在');
    }
    if (user.password !== password) {
      throw new Error('密码错误');
    }

    // 保存登录态到 AppStorage
    AppStorage.setOrCreate<number>('currentUserId', user.id);
    AppStorage.setOrCreate<string>('currentUsername', user.username);
    AppStorage.setOrCreate<string>('currentNickname', user.nickname);
    AppStorage.setOrCreate<boolean>('isLoggedIn', true);
    hilog.info(DOMAIN, TAG, `User logged in: ${username}, id=${user.id}`);
    return user;
  }

  // 退出登录
  logout(): void {
    AppStorage.setOrCreate<number>('currentUserId', -1);
    AppStorage.setOrCreate<string>('currentUsername', '');
    AppStorage.setOrCreate<string>('currentNickname', '');
    AppStorage.setOrCreate<boolean>('isLoggedIn', false);
    AppStorage.setOrCreate<number>('currentPetId', -1);
    hilog.info(DOMAIN, TAG, 'User logged out');
  }

  // 密码找回（通过用户名+手机号重置）
  async resetPassword(username: string, phone: string, newPassword: string): Promise<boolean> {
    const user = await this.findByUsername(username);
    if (!user) {
      throw new Error('用户不存在');
    }
    if (user.phone !== phone) {
      throw new Error('手机号不匹配');
    }
    const predicates = new relationalStore.RdbPredicates('user_info');
    predicates.equalTo('id', user.id);
    const values: relationalStore.ValuesBucket = {
      'password': newPassword,
      'updated_at': new Date().toISOString()
    };
    const rows = await RdbHelper.update(values, predicates);
    return rows > 0;
  }

  // 更新用户信息
  async updateProfile(userId: number, nickname?: string, phone?: string,
    email?: string): Promise<boolean> {
    const predicates = new relationalStore.RdbPredicates('user_info');
    predicates.equalTo('id', userId);
    const values: relationalStore.ValuesBucket = {
      'updated_at': new Date().toISOString()
    };
    if (nickname !== undefined) {
      values['nickname'] = nickname;
    }
    if (phone !== undefined) {
      values['phone'] = phone;
    }
    if (email !== undefined) {
      values['email'] = email;
    }
    const rows = await RdbHelper.update(values, predicates);
    if (rows > 0 && nickname) {
      AppStorage.setOrCreate<string>('currentNickname', nickname);
    }
    return rows > 0;
  }

  // 根据用户名查找用户
  async findByUsername(username: string): Promise<UserEntity | null> {
    hilog.info(DOMAIN, TAG, `Finding user by username: ${username}`);
    const predicates = new relationalStore.RdbPredicates('user_info');
    predicates.equalTo('username', username);
    const resultSet = await RdbHelper.query('user_info', predicates);
    try {
      if (resultSet.goToFirstRow()) {
        const user = this.mapResultToUser(resultSet);
        hilog.info(DOMAIN, TAG, `Found user: id=${user.id}, username=${user.username}`);
        return user;
      }
      hilog.info(DOMAIN, TAG, `User not found: ${username}`);
      return null;
    } finally {
      resultSet.close();
    }
  }

  // 根据 ID 查找用户
  async findById(userId: number): Promise<UserEntity | null> {
    const predicates = new relationalStore.RdbPredicates('user_info');
    predicates.equalTo('id', userId);
    const resultSet = await RdbHelper.query('user_info', predicates);
    try {
      if (resultSet.goToFirstRow()) {
        return this.mapResultToUser(resultSet);
      }
      return null;
    } finally {
      resultSet.close();
    }
  }

  // 获取当前登录用户 ID
  getCurrentUserId(): number {
    return AppStorage.get<number>('currentUserId') ?? -1;
  }

  // 是否已登录
  isLoggedIn(): boolean {
    return AppStorage.get<boolean>('isLoggedIn') ?? false;
  }

  // ResultSet 映射为 UserEntity
  private mapResultToUser(rs: relationalStore.ResultSet): UserEntity {
    return {
      id: rs.getLong(rs.getColumnIndex('id')),
      username: rs.getString(rs.getColumnIndex('username')),
      password: rs.getString(rs.getColumnIndex('password')),
      nickname: rs.getString(rs.getColumnIndex('nickname')),
      phone: rs.getString(rs.getColumnIndex('phone')),
      email: rs.getString(rs.getColumnIndex('email')),
      avatar: rs.getString(rs.getColumnIndex('avatar')),
      isVip: rs.getLong(rs.getColumnIndex('is_vip')) === 1,
      createdAt: rs.getString(rs.getColumnIndex('created_at')),
      updatedAt: rs.getString(rs.getColumnIndex('updated_at'))
    };
  }
}

export const UserService = new UserServiceClass();
