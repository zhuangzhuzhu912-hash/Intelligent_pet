// 宠物管理页面 — 添加/编辑/删除宠物档案
import { AppColors, AppSizes, AppFonts } from '../common/constants/AppConstants';
import { GlassCard } from '../components/CommonComponents';
import { PetService } from '../services/PetService';
import type { PetEntity } from '../services/PetService';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'PetManagePage';

@Entry
@Component
struct PetManagePage {
  @State private pets: PetEntity[] = [];
  @State private isLoading: boolean = false;
  // 编辑/添加表单状态
  @State private showForm: boolean = false;
  @State private editingPetId: number = -1;
  @State private formName: string = '';
  @State private formBreed: string = '';
  @State private formAge: string = '';
  @State private formGender: string = '公';
  @State private formWeight: string = '';
  @State private errorMsg: string = '';

  private genderOptions: string[] = ['公', '母', '未知'];

  aboutToAppear(): void {
    this.loadPets();
  }

  private async loadPets(): Promise<void> {
    this.isLoading = true;
    try {
      this.pets = await PetService.getPetsByCurrentUser();
    } catch (err) {
      hilog.error(0x0000, TAG, `Load pets failed: ${JSON.stringify(err)}`);
    } finally {
      this.isLoading = false;
    }
  }

  private resetForm(): void {
    this.editingPetId = -1;
    this.formName = '';
    this.formBreed = '';
    this.formAge = '';
    this.formGender = '公';
    this.formWeight = '';
    this.errorMsg = '';
  }

  private openAddForm(): void {
    this.resetForm();
    this.showForm = true;
  }

  private openEditForm(pet: PetEntity): void {
    this.editingPetId = pet.id;
    this.formName = pet.name;
    this.formBreed = pet.breed;
    this.formAge = pet.age > 0 ? pet.age.toString() : '';
    this.formGender = pet.gender;
    this.formWeight = pet.weight > 0 ? pet.weight.toString() : '';
    this.errorMsg = '';
    this.showForm = true;
  }

  private async handleSave(): Promise<void> {
    if (!this.formName.trim()) {
      this.errorMsg = '请输入宠物名称';
      return;
    }
    this.errorMsg = '';
    try {
      const petData: Partial<PetEntity> = {
        name: this.formName.trim(),
        breed: this.formBreed.trim(),
        age: this.formAge ? parseFloat(this.formAge) : 0,
        gender: this.formGender,
        weight: this.formWeight ? parseFloat(this.formWeight) : 0
      };
      if (this.editingPetId > 0) {
        await PetService.updatePet(this.editingPetId, petData);
      } else {
        const newId = await PetService.addPet(petData);
        // 若当前无选中宠物，自动选中新添加的宠物
        if (PetService.getCurrentPetId() <= 0) {
          PetService.setCurrentPet(newId);
        }
      }
      this.showForm = false;
      this.resetForm();
      await this.loadPets();
    } catch (err) {
      const error = err as Error;
      this.errorMsg = error.message || '保存失败';
      hilog.error(0x0000, TAG, `Save pet failed: ${JSON.stringify(err)}`);
    }
  }

  private async handleDelete(petId: number): Promise<void> {
    try {
      await PetService.deletePet(petId);
      // 如果删除的是当前选中的宠物，切换到第一只
      if (PetService.getCurrentPetId() === petId) {
        const remaining = this.pets.filter(p => p.id !== petId);
        if (remaining.length > 0) {
          PetService.setCurrentPet(remaining[0].id);
        } else {
          PetService.setCurrentPet(-1);
        }
      }
      await this.loadPets();
    } catch (err) {
      hilog.error(0x0000, TAG, `Delete pet failed: ${JSON.stringify(err)}`);
    }
  }

  private handleSelectPet(petId: number): void {
    PetService.setCurrentPet(petId);
    router.back();
  }

  @Builder
  private buildPetCard(pet: PetEntity) {
    GlassCard() {
      Row({ space: 12 }) {
        // 头像
        Stack() {
          Text('🐾')
            .fontSize(28)
            .width(56)
            .height(56)
            .textAlign(TextAlign.Center)
            .backgroundColor(AppColors.PRIMARY_10)
            .borderRadius(28)
          // 当前选中标记
          if (PetService.getCurrentPetId() === pet.id) {
            Circle()
              .width(14)
              .height(14)
              .fill(AppColors.SUCCESS)
              .stroke(Color.White)
              .strokeWidth(2)
              .position({ x: 42, y: 0 })
          }
        }
        .width(56)
        .height(56)

        // 信息
        Column({ space: 4 }) {
          Row({ space: 8 }) {
            Text(pet.name)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT_PRIMARY)
            if (PetService.getCurrentPetId() === pet.id) {
              Text('当前')
                .fontSize(AppFonts.SMALL)
                .fontColor(AppColors.SUCCESS)
                .backgroundColor(AppColors.SUCCESS_10)
                .padding({ left: 6, right: 6, top: 1, bottom: 1 })
                .borderRadius(8)
            }
          }
          Text(`${pet.breed || '未知品种'} · ${pet.age > 0 ? pet.age + '岁' : '年龄未知'} · ${pet.gender}`)
            .fontSize(AppFonts.CAPTION)
            .fontColor(AppColors.TEXT_SECONDARY)
          if (pet.weight > 0) {
            Text(`体重: ${pet.weight}kg`)
              .fontSize(AppFonts.SMALL)
              .fontColor(AppColors.TEXT_HINT)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 操作按钮
        Column({ space: 8 }) {
          Text('编辑')
            .fontSize(AppFonts.CAPTION)
            .fontColor(AppColors.PRIMARY)
            .onClick(() => {
              this.openEditForm(pet);
            })
          Text('删除')
            .fontSize(AppFonts.CAPTION)
            .fontColor(AppColors.DANGER)
            .onClick(() => {
              this.handleDelete(pet.id);
            })
        }
      }
      .width('100%')
      .onClick(() => {
        this.handleSelectPet(pet.id);
      })
    }
  }

  @Builder
  private buildForm() {
    Column({ space: 16 }) {
      // 表单标题
      Row() {
        Text(this.editingPetId > 0 ? '编辑宠物' : '添加宠物')
          .fontSize(AppFonts.SUBTITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
        Blank()
        Text('取消')
          .fontSize(AppFonts.BODY)
          .fontColor(AppColors.TEXT_SECONDARY)
          .onClick(() => {
            this.showForm = false;
            this.resetForm();
          })
      }
      .width('100%')

      // 名称（必填）
      Column({ space: 4 }) {
        Text('名称 *')
          .fontSize(AppFonts.BODY)
          .fontColor(AppColors.TEXT_PRIMARY)
        TextInput({ placeholder: '宠物名称', text: this.formName })
          .height(44)
          .borderRadius(12)
          .backgroundColor('#F3F4F6')
          .padding({ left: 12, right: 12 })
          .fontSize(AppFonts.BODY)
          .onChange((v: string) => {
            this.formName = v;
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 品种
      Column({ space: 4 }) {
        Text('品种')
          .fontSize(AppFonts.BODY)
          .fontColor(AppColors.TEXT_PRIMARY)
        TextInput({ placeholder: '如：柯基、英短', text: this.formBreed })
          .height(44)
          .borderRadius(12)
          .backgroundColor('#F3F4F6')
          .padding({ left: 12, right: 12 })
          .fontSize(AppFonts.BODY)
          .onChange((v: string) => {
            this.formBreed = v;
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 年龄 + 体重
      Row({ space: 12 }) {
        Column({ space: 4 }) {
          Text('年龄')
            .fontSize(AppFonts.BODY)
            .fontColor(AppColors.TEXT_PRIMARY)
          TextInput({ placeholder: '岁', text: this.formAge })
            .type(InputType.Number)
            .height(44)
            .borderRadius(12)
            .backgroundColor('#F3F4F6')
            .padding({ left: 12, right: 12 })
            .fontSize(AppFonts.BODY)
            .onChange((v: string) => {
              this.formAge = v;
            })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Column({ space: 4 }) {
          Text('体重(kg)')
            .fontSize(AppFonts.BODY)
            .fontColor(AppColors.TEXT_PRIMARY)
          TextInput({ placeholder: 'kg', text: this.formWeight })
            .type(InputType.Number)
            .height(44)
            .borderRadius(12)
            .backgroundColor('#F3F4F6')
            .padding({ left: 12, right: 12 })
            .fontSize(AppFonts.BODY)
            .onChange((v: string) => {
              this.formWeight = v;
            })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      // 性别选择
      Column({ space: 4 }) {
        Text('性别')
          .fontSize(AppFonts.BODY)
          .fontColor(AppColors.TEXT_PRIMARY)
        Row({ space: 8 }) {
          ForEach(this.genderOptions, (g: string) => {
            Text(g)
              .fontSize(AppFonts.BODY)
              .fontColor(this.formGender === g ? Color.White : AppColors.TEXT_PRIMARY)
              .backgroundColor(this.formGender === g ? AppColors.PRIMARY : '#F3F4F6')
              .padding({ left: 20, right: 20, top: 8, bottom: 8 })
              .borderRadius(20)
              .onClick(() => {
                this.formGender = g;
              })
          })
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 错误提示
      if (this.errorMsg.length > 0) {
        Text(this.errorMsg)
          .fontSize(AppFonts.CAPTION)
          .fontColor(AppColors.DANGER)
          .width('100%')
      }

      // 保存按钮
      Button(this.editingPetId > 0 ? '保存修改' : '添加宠物')
        .width('100%')
        .height(44)
        .fontSize(AppFonts.BODY)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .backgroundColor(AppColors.PRIMARY)
        .borderRadius(AppSizes.BTN_RADIUS)
        .onClick(() => {
          this.handleSave();
        })
    }
    .width('100%')
    .padding(AppSizes.CARD_PADDING)
    .backgroundColor(AppColors.CARD_BG)
    .borderRadius(AppSizes.CARD_RADIUS)
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.04)', offsetY: 4 })
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(24)
          .height(24)
          .fillColor(AppColors.TEXT_PRIMARY)
          .onClick(() => {
            router.back();
          })
        Text('宠物管理')
          .fontSize(AppFonts.TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .margin({ left: 12 })
        Blank()
        if (!this.showForm) {
          Button('添加')
            .fontSize(AppFonts.CAPTION)
            .fontColor(Color.White)
            .backgroundColor(AppColors.PRIMARY)
            .borderRadius(20)
            .height(32)
            .padding({ left: 14, right: 14 })
            .onClick(() => {
              this.openAddForm();
            })
        }
      }
      .width('100%')
      .padding({ left: AppSizes.PAGE_PADDING, right: AppSizes.PAGE_PADDING, top: 56, bottom: 12 })

      // 内容区
      Scroll() {
        Column({ space: AppSizes.CARD_GAP }) {
          // 添加/编辑表单
          if (this.showForm) {
            this.buildForm()
          }

          // 宠物列表
          if (this.pets.length === 0 && !this.showForm) {
            Column({ space: 12 }) {
              Text('🐾')
                .fontSize(48)
              Text('还没有添加宠物')
                .fontSize(AppFonts.BODY)
                .fontColor(AppColors.TEXT_SECONDARY)
              Text('点击右上角"添加"按钮添加你的第一只宠物')
                .fontSize(AppFonts.CAPTION)
                .fontColor(AppColors.TEXT_HINT)
            }
            .width('100%')
            .padding({ top: 80 })
            .alignItems(HorizontalAlign.Center)
          } else {
            // 提示
            if (!this.showForm) {
              Text('点击宠物卡片可切换为当前宠物')
                .fontSize(AppFonts.CAPTION)
                .fontColor(AppColors.TEXT_HINT)
                .width('100%')
            }

            ForEach(this.pets, (pet: PetEntity) => {
              this.buildPetCard(pet)
            })
          }
        }
        .width('100%')
        .padding({
          left: AppSizes.PAGE_PADDING,
          right: AppSizes.PAGE_PADDING,
          top: 4,
          bottom: 16
        })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }
}
