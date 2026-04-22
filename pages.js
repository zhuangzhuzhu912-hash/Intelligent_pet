// 首页内容 - 完整版本
const homePage = `
<div class="flex justify-between items-center mb-4 px-1">
    <div class="flex items-center gap-2">
        <i class="fas fa-bolt text-primary text-2xl"></i>
        <h1 class="text-xl font-bold text-gray-800">宠联中枢</h1>
    </div>
    <div class="flex items-center gap-2">
        <span class="bg-white/80 backdrop-blur-sm px-3 py-1.5 rounded-full text-sm text-gray-600 shadow-sm">
            <i class="fas fa-microchip text-primary mr-1"></i>16台设备
        </span>
        <button class="w-10 h-10 rounded-full bg-white/80 backdrop-blur-sm shadow-sm text-gray-600">
            <i class="fas fa-bell"></i>
        </button>
    </div>
</div>

<div class="glass-card rounded-card p-4 mb-4 shadow-card">
    <div class="flex items-center gap-3">
        <div class="relative">
            <img src="https://images.unsplash.com/photo-1612940960267-4549a58fb257?w=150&h=150&fit=crop" 
                 class="w-14 h-14 rounded-full object-cover border-2 border-white shadow-sm">
            <span class="online-dot"></span>
        </div>
        <div>
            <div class="flex items-center gap-2">
                <h2 class="text-lg font-bold text-gray-800">旺仔</h2>
                <span class="bg-primary/10 text-primary text-xs px-2 py-0.5 rounded-full">柯基·3岁</span>
            </div>
            <p class="text-gray-500 text-sm"><i class="fas fa-weight-scale mr-1"></i>12.5kg · 公 · 疫苗齐全</p>
        </div>
    </div>
</div>

<div class="glass-card rounded-card p-4 mb-4 shadow-card">
    <div class="flex justify-between items-center mb-3">
        <div class="flex items-center gap-2">
            <i class="fas fa-dog text-secondary text-lg"></i>
            <h3 class="font-semibold text-gray-800">智能项圈</h3>
            <span class="text-xs bg-secondary/10 text-secondary px-2 py-0.5 rounded-full">在线</span>
        </div>
        <span class="text-xs text-gray-400"><i class="far fa-clock mr-1"></i>更新于30秒前</span>
    </div>
    
    <div class="relative rounded-2xl overflow-hidden h-36 mb-3 border border-gray-200/50">
        <img src="https://images.unsplash.com/photo-1524661135-423995f22d0b?w=800&h=300&fit=crop" 
             class="w-full h-full object-cover">
        <div class="absolute inset-0 bg-gradient-to-t from-black/30 to-transparent"></div>
        <div class="absolute bottom-3 left-3 right-3 flex items-center justify-between">
            <div class="flex items-center gap-2 bg-white/90 backdrop-blur-sm px-3 py-1.5 rounded-full">
                <img src="https://images.unsplash.com/photo-1612940960267-4549a58fb257?w=30&h=30&fit=crop" 
                     class="w-6 h-6 rounded-full border border-white">
                <span class="text-sm font-medium text-gray-800">旺仔</span>
            </div>
            <button class="bg-primary text-white w-10 h-10 rounded-full flex items-center justify-center shadow-lg">
                <i class="fas fa-location-arrow"></i>
            </button>
        </div>
    </div>
    
    <div class="mb-3">
        <p class="text-gray-800 font-medium"><i class="fas fa-map-pin text-secondary mr-1"></i>广东省广州市天河区·天河北路890号</p>
        <p class="text-gray-500 text-sm mt-1">距您 1.2km · 在小区内活动</p>
    </div>
    
    <div class="grid grid-cols-4 gap-2 mb-3">
        <button class="bg-primary/10 rounded-xl py-2 flex flex-col items-center">
            <i class="fas fa-search text-primary text-lg"></i>
            <span class="text-xs text-gray-700 mt-1">一键寻宠</span>
        </button>
        <button class="bg-secondary/10 rounded-xl py-2 flex flex-col items-center relative">
            <i class="fas fa-microphone text-secondary text-lg"></i>
            <span class="text-xs text-gray-700 mt-1">语音对讲</span>
            <span class="absolute inset-0 rounded-xl border-2 border-secondary/30 sonar-wave"></span>
        </button>
        <button class="bg-gray-100 rounded-xl py-2 flex flex-col items-center">
            <i class="fas fa-route text-gray-600 text-lg"></i>
            <span class="text-xs text-gray-700 mt-1">历史轨迹</span>
        </button>
        <button class="bg-gray-100 rounded-xl py-2 flex flex-col items-center">
            <i class="fas fa-shield-alt text-gray-600 text-lg"></i>
            <span class="text-xs text-gray-700 mt-1">电子围栏</span>
        </button>
    </div>
    
    <div class="border-t border-gray-100 pt-3">
        <div class="flex items-center justify-between mb-2">
            <span class="text-sm font-medium text-gray-700"><i class="fas fa-person-running text-secondary mr-1"></i>今日运动</span>
            <span class="text-xs text-gray-400">目标 8000步</span>
        </div>
        <div class="flex items-center gap-4">
            <div class="relative w-20 h-20">
                <svg class="w-full h-full -rotate-90" viewBox="0 0 100 100">
                    <circle cx="50" cy="50" r="38" fill="none" stroke="#E8E8E8" stroke-width="6"></circle>
                    <circle cx="50" cy="50" r="38" fill="none" stroke="url(#grad)" stroke-width="6" 
                            stroke-linecap="round" stroke-dasharray="238.76" stroke-dashoffset="83.57"></circle>
                    <defs>
                        <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
                            <stop offset="0%" stop-color="#FF9F43"/>
                            <stop offset="100%" stop-color="#00B4D8"/>
                        </linearGradient>
                    </defs>
                </svg>
                <div class="absolute inset-0 flex flex-col items-center justify-center">
                    <span class="text-lg font-bold text-gray-800">65<small class="text-[10px]">%</small></span>
                </div>
            </div>
            <div class="flex-1 grid grid-cols-3 gap-1">
                <div class="bg-white/60 rounded-lg p-1.5 text-center">
                    <p class="text-base font-bold text-gray-800">5.2k</p>
                    <p class="text-[10px] text-gray-400">步数</p>
                </div>
                <div class="bg-white/60 rounded-lg p-1.5 text-center">
                    <p class="text-base font-bold text-gray-800">3.8</p>
                    <p class="text-[10px] text-gray-400">公里</p>
                </div>
                <div class="bg-white/60 rounded-lg p-1.5 text-center">
                    <p class="text-base font-bold text-gray-800">215</p>
                    <p class="text-[10px] text-gray-400">千卡</p>
                </div>
            </div>
        </div>
        <p class="text-xs text-success mt-2"><i class="fas fa-arrow-trend-up mr-1"></i>较昨日 +12%</p>
    </div>
</div>

<div class="glass-card rounded-card p-4 mb-4 shadow-card">
    <div class="flex justify-between items-center mb-3">
        <div class="flex items-center gap-2">
            <i class="fas fa-utensils text-primary text-lg"></i>
            <h3 class="font-semibold text-gray-800">智能喂食器</h3>
            <span class="text-xs bg-success/10 text-success px-2 py-0.5 rounded-full">在线</span>
        </div>
        <span class="text-xs text-gray-400"><i class="far fa-clock mr-1"></i>下一餐 18:30</span>
    </div>
    
    <div class="flex justify-around mb-4">
        <div class="text-center">
            <div class="relative w-20 h-20 mx-auto">
                <svg class="w-full h-full -rotate-90" viewBox="0 0 100 100">
                    <circle cx="50" cy="50" r="38" fill="none" stroke="#E8E8E8" stroke-width="6"></circle>
                    <circle cx="50" cy="50" r="38" fill="none" stroke="#FF9F43" stroke-width="6" 
                            stroke-dasharray="238.76" stroke-dashoffset="95.5"></circle>
                </svg>
                <div class="absolute inset-0 flex flex-col items-center justify-center">
                    <span class="text-lg font-bold">68<small class="text-[10px]">g</small></span>
                    <span class="text-[10px] text-gray-400">余粮</span>
                </div>
            </div>
            <p class="text-xs text-gray-400 mt-1">容量200g</p>
        </div>
        <div class="text-center">
            <div class="relative w-20 h-20 mx-auto">
                <svg class="w-full h-full -rotate-90" viewBox="0 0 100 100">
                    <circle cx="50" cy="50" r="38" fill="none" stroke="#E8E8E8" stroke-width="6"></circle>
                    <circle cx="50" cy="50" r="38" fill="none" stroke="#00B4D8" stroke-width="6" 
                            stroke-dasharray="238.76" stroke-dashoffset="47.75"></circle>
                </svg>
                <div class="absolute inset-0 flex flex-col items-center justify-center">
                    <span class="text-lg font-bold">320<small class="text-[10px]">ml</small></span>
                    <span class="text-[10px] text-gray-400">水量</span>
                </div>
            </div>
            <p class="text-xs text-gray-400 mt-1">容量500ml</p>
        </div>
    </div>
    
    <div class="bg-gradient-to-r from-primary/5 to-secondary/5 rounded-xl p-3 mb-4">
        <div class="flex items-center justify-between mb-2">
            <span class="text-sm font-medium"><i class="far fa-calendar-alt mr-1"></i>今日喂食计划</span>
            <span class="text-xs text-primary bg-white/80 px-2 py-0.5 rounded-full">运动自适应开启</span>
        </div>
        <div class="space-y-1.5">
            <div class="flex justify-between text-sm">
                <span class="text-gray-600">08:00 早餐</span>
                <span class="font-medium">30g <span class="text-success text-xs">已完成</span></span>
            </div>
            <div class="flex justify-between text-sm">
                <span class="text-gray-600">12:30 午餐</span>
                <span class="font-medium">25g <span class="text-warning text-xs">待执行</span></span>
            </div>
            <div class="flex justify-between text-sm">
                <span class="text-gray-600">18:30 晚餐</span>
                <span class="font-medium">35g (预估) <span class="text-gray-400 text-xs">将根据运动调整</span></span>
            </div>
        </div>
    </div>
    
    <div class="flex gap-3 mb-4">
        <button class="flex-1 bg-primary text-white py-3 rounded-btn font-medium flex items-center justify-center gap-2 shadow-btn feed-btn-glow">
            <i class="fas fa-plus-circle"></i>立即加餐
        </button>
        <button class="flex-1 bg-white border border-gray-200 text-gray-700 py-3 rounded-btn font-medium flex items-center justify-center gap-2">
            <i class="fas fa-sliders-h"></i>自定义投喂
        </button>
    </div>
    
    <div>
        <div class="flex justify-between items-center mb-2">
            <span class="text-sm font-medium text-gray-700"><i class="far fa-list-alt mr-1"></i>今日记录</span>
            <a href="#" class="text-xs text-primary">全部 <i class="fas fa-chevron-right text-[10px]"></i></a>
        </div>
        <div class="space-y-2">
            <div class="flex items-center justify-between p-2 bg-white/50 rounded-lg">
                <div class="flex items-center gap-2">
                    <i class="far fa-clock text-primary"></i>
                    <span class="text-sm">08:00 定时</span>
                </div>
                <span class="font-medium">30g</span>
            </div>
            <div class="flex items-center justify-between p-2 bg-white/50 rounded-lg">
                <div class="flex items-center gap-2">
                    <i class="fas fa-bolt text-secondary"></i>
                    <span class="text-sm">10:15 运动奖励</span>
                </div>
                <span class="font-medium text-secondary">+10g</span>
            </div>
            <div class="flex items-center justify-between p-2 bg-white/50 rounded-lg">
                <div class="flex items-center gap-2">
                    <i class="fas fa-hand-pointer text-gray-500"></i>
                    <span class="text-sm">14:20 手动加餐</span>
                </div>
                <span class="font-medium">15g</span>
            </div>
        </div>
    </div>
</div>

<div class="glass-card rounded-card p-3 mb-3">
    <div class="flex items-center justify-between mb-2">
        <span class="text-sm font-medium text-gray-700"><i class="fas fa-th mr-1"></i>其他设备</span>
        <span class="text-xs text-primary">13台在线</span>
    </div>
    <div class="flex gap-3 overflow-x-auto pb-1">
        <div class="flex flex-col items-center min-w-[60px]">
            <div class="w-12 h-12 rounded-full bg-blue-50 flex items-center justify-center"><i class="fas fa-water text-blue-400 text-xl"></i></div>
            <span class="text-xs mt-1">饮水机</span>
        </div>
        <div class="flex flex-col items-center min-w-[60px]">
            <div class="w-12 h-12 rounded-full bg-green-50 flex items-center justify-center"><i class="fas fa-toilet text-green-400 text-xl"></i></div>
            <span class="text-xs mt-1">猫砂盆</span>
        </div>
        <div class="flex flex-col items-center min-w-[60px]">
            <div class="w-12 h-12 rounded-full bg-purple-50 flex items-center justify-center"><i class="fas fa-video text-purple-400 text-xl"></i></div>
            <span class="text-xs mt-1">摄像头</span>
        </div>
        <div class="flex flex-col items-center min-w-[60px]">
            <div class="w-12 h-12 rounded-full bg-orange-50 flex items-center justify-center"><i class="fas fa-temperature-high text-orange-400 text-xl"></i></div>
            <span class="text-xs mt-1">温湿度计</span>
        </div>
        <div class="flex flex-col items-center min-w-[60px]">
            <div class="w-12 h-12 rounded-full bg-gray-100 flex items-center justify-center"><i class="fas fa-plus text-gray-400"></i></div>
            <span class="text-xs mt-1">添加</span>
        </div>
    </div>
</div>

<div class="glass-card rounded-2xl p-3 mb-16 bg-gradient-to-r from-primary/10 to-secondary/10 border border-primary/20 flex items-center gap-2">
    <i class="fas fa-link text-primary"></i>
    <span class="text-sm text-gray-700">分布式联动已激活 · 今日运动奖励已触发1次</span>
    <i class="fas fa-check-circle text-success ml-auto"></i>
</div>
`;

// 设备页面内容
const devicesPage = `
<div class="flex justify-between items-center mb-4 px-1">
    <h1 class="text-xl font-bold text-gray-800">我的设备</h1>
    <button class="bg-primary text-white px-4 py-2 rounded-full text-sm">
        <i class="fas fa-plus mr-1"></i>添加设备
    </button>
</div>

<div class="glass-card rounded-card p-4 mb-3 shadow-card">
    <div class="flex items-center justify-between mb-3">
        <div class="flex items-center gap-3">
            <div class="w-12 h-12 rounded-xl bg-gradient-to-br from-primary to-orange-500 flex items-center justify-center text-white text-xl">
                <i class="fas fa-dog"></i>
            </div>
            <div>
                <h3 class="font-semibold text-gray-800">智能项圈</h3>
                <p class="text-xs text-gray-500">型号: PetCollar Pro</p>
            </div>
        </div>
        <div class="text-right">
            <span class="text-xs bg-success/10 text-success px-2 py-1 rounded-full">在线</span>
            <p class="text-xs text-gray-400 mt-1">电量 87%</p>
        </div>
    </div>
    <div class="grid grid-cols-3 gap-2 text-center text-xs">
        <div class="bg-gray-50 rounded-lg py-2">
            <p class="font-bold text-gray-800">GPS</p>
            <p class="text-gray-500">定位</p>
        </div>
        <div class="bg-gray-50 rounded-lg py-2">
            <p class="font-bold text-gray-800">运动</p>
            <p class="text-gray-500">监测</p>
        </div>
        <div class="bg-gray-50 rounded-lg py-2">
            <p class="font-bold text-gray-800">语音</p>
            <p class="text-gray-500">对讲</p>
        </div>
    </div>
</div>

<div class="glass-card rounded-card p-4 mb-3 shadow-card">
    <div class="flex items-center justify-between mb-3">
        <div class="flex items-center gap-3">
            <div class="w-12 h-12 rounded-xl bg-gradient-to-br from-secondary to-blue-500 flex items-center justify-center text-white text-xl">
                <i class="fas fa-utensils"></i>
            </div>
            <div>
                <h3 class="font-semibold text-gray-800">智能喂食器</h3>
                <p class="text-xs text-gray-500">型号: AutoFeeder X1</p>
            </div>
        </div>
        <div class="text-right">
            <span class="text-xs bg-success/10 text-success px-2 py-1 rounded-full">在线</span>
            <p class="text-xs text-gray-400 mt-1">余粮 68%</p>
        </div>
    </div>
    <div class="grid grid-cols-3 gap-2 text-center text-xs">
        <div class="bg-gray-50 rounded-lg py-2">
            <p class="font-bold text-gray-800">定时</p>
            <p class="text-gray-500">投喂</p>
        </div>
        <div class="bg-gray-50 rounded-lg py-2">
            <p class="font-bold text-gray-800">智能</p>
            <p class="text-gray-500">联动</p>
        </div>
        <div class="bg-gray-50 rounded-lg py-2">
            <p class="font-bold text-gray-800">远程</p>
            <p class="text-gray-500">控制</p>
        </div>
    </div>
</div>

<div class="glass-card rounded-card p-4 mb-3 shadow-card">
    <div class="flex items-center justify-between mb-3">
        <div class="flex items-center gap-3">
            <div class="w-12 h-12 rounded-xl bg-gradient-to-br from-blue-400 to-cyan-500 flex items-center justify-center text-white text-xl">
                <i class="fas fa-water"></i>
            </div>
            <div>
                <h3 class="font-semibold text-gray-800">智能饮水机</h3>
                <p class="text-xs text-gray-500">型号: WaterFlow Plus</p>
            </div>
        </div>
        <div class="text-right">
            <span class="text-xs bg-success/10 text-success px-2 py-1 rounded-full">在线</span>
            <p class="text-xs text-gray-400 mt-1">水量 64%</p>
        </div>
    </div>
</div>

<div class="glass-card rounded-card p-4 mb-16 shadow-card">
    <h3 class="font-semibold text-gray-800 mb-3">更多设备 (13台)</h3>
    <div class="grid grid-cols-4 gap-3">
        <div class="text-center">
            <div class="w-12 h-12 rounded-full bg-purple-50 flex items-center justify-center mx-auto mb-1">
                <i class="fas fa-video text-purple-400 text-lg"></i>
            </div>
            <p class="text-xs text-gray-600">摄像头</p>
        </div>
        <div class="text-center">
            <div class="w-12 h-12 rounded-full bg-green-50 flex items-center justify-center mx-auto mb-1">
                <i class="fas fa-toilet text-green-400 text-lg"></i>
            </div>
            <p class="text-xs text-gray-600">猫砂盆</p>
        </div>
        <div class="text-center">
            <div class="w-12 h-12 rounded-full bg-orange-50 flex items-center justify-center mx-auto mb-1">
                <i class="fas fa-temperature-high text-orange-400 text-lg"></i>
            </div>
            <p class="text-xs text-gray-600">温湿度</p>
        </div>
        <div class="text-center">
            <div class="w-12 h-12 rounded-full bg-pink-50 flex items-center justify-center mx-auto mb-1">
                <i class="fas fa-gamepad text-pink-400 text-lg"></i>
            </div>
            <p class="text-xs text-gray-600">玩具</p>
        </div>
    </div>
</div>
`;

// 健康页面内容
const healthPage = `
<div class="flex justify-between items-center mb-4 px-1">
    <h1 class="text-xl font-bold text-gray-800">健康档案</h1>
    <button class="text-primary text-sm">
        <i class="fas fa-calendar-alt mr-1"></i>查看历史
    </button>
</div>

<div class="glass-card rounded-card p-4 mb-3 shadow-card">
    <div class="flex items-center gap-3 mb-4">
        <img src="https://images.unsplash.com/photo-1612940960267-4549a58fb257?w=150&h=150&fit=crop" 
             class="w-16 h-16 rounded-full object-cover border-2 border-white shadow-sm">
        <div class="flex-1">
            <h2 class="text-lg font-bold text-gray-800">旺仔</h2>
            <p class="text-sm text-gray-500">柯基 · 3岁 · 公</p>
            <div class="flex gap-2 mt-1">
                <span class="text-xs bg-success/10 text-success px-2 py-0.5 rounded-full">健康</span>
                <span class="text-xs bg-primary/10 text-primary px-2 py-0.5 rounded-full">已绝育</span>
            </div>
        </div>
    </div>
    
    <div class="grid grid-cols-3 gap-3 text-center">
        <div class="bg-gradient-to-br from-primary/10 to-orange-50 rounded-xl p-3">
            <p class="text-2xl font-bold text-gray-800">12.5</p>
            <p class="text-xs text-gray-500">体重(kg)</p>
        </div>
        <div class="bg-gradient-to-br from-secondary/10 to-blue-50 rounded-xl p-3">
            <p class="text-2xl font-bold text-gray-800">38.2</p>
            <p class="text-xs text-gray-500">体温(°C)</p>
        </div>
        <div class="bg-gradient-to-br from-success/10 to-green-50 rounded-xl p-3">
            <p class="text-2xl font-bold text-gray-800">78</p>
            <p class="text-xs text-gray-500">心率(bpm)</p>
        </div>
    </div>
</div>

<div class="glass-card rounded-card p-4 mb-3 shadow-card">
    <h3 class="font-semibold text-gray-800 mb-3"><i class="fas fa-chart-line text-primary mr-2"></i>本周运动趋势</h3>
    <div class="flex items-end justify-between h-32 gap-2">
        <div class="flex-1 flex flex-col items-center">
            <div class="w-full bg-gradient-to-t from-primary to-orange-300 rounded-t-lg" style="height: 60%"></div>
            <p class="text-xs text-gray-500 mt-1">周一</p>
        </div>
        <div class="flex-1 flex flex-col items-center">
            <div class="w-full bg-gradient-to-t from-primary to-orange-300 rounded-t-lg" style="height: 75%"></div>
            <p class="text-xs text-gray-500 mt-1">周二</p>
        </div>
        <div class="flex-1 flex flex-col items-center">
            <div class="w-full bg-gradient-to-t from-primary to-orange-300 rounded-t-lg" style="height: 50%"></div>
            <p class="text-xs text-gray-500 mt-1">周三</p>
        </div>
        <div class="flex-1 flex flex-col items-center">
            <div class="w-full bg-gradient-to-t from-primary to-orange-300 rounded-t-lg" style="height: 85%"></div>
            <p class="text-xs text-gray-500 mt-1">周四</p>
        </div>
        <div class="flex-1 flex flex-col items-center">
            <div class="w-full bg-gradient-to-t from-primary to-orange-300 rounded-t-lg" style="height: 70%"></div>
            <p class="text-xs text-gray-500 mt-1">周五</p>
        </div>
        <div class="flex-1 flex flex-col items-center">
            <div class="w-full bg-gradient-to-t from-primary to-orange-300 rounded-t-lg" style="height: 90%"></div>
            <p class="text-xs text-gray-500 mt-1">周六</p>
        </div>
        <div class="flex-1 flex flex-col items-center">
            <div class="w-full bg-gradient-to-t from-secondary to-blue-300 rounded-t-lg" style="height: 65%"></div>
            <p class="text-xs text-gray-500 mt-1">今天</p>
        </div>
    </div>
</div>

<div class="glass-card rounded-card p-4 mb-3 shadow-card">
    <h3 class="font-semibold text-gray-800 mb-3"><i class="fas fa-syringe text-secondary mr-2"></i>疫苗接种记录</h3>
    <div class="space-y-3">
        <div class="flex items-center justify-between p-3 bg-success/5 rounded-lg">
            <div>
                <p class="font-medium text-gray-800">狂犬疫苗</p>
                <p class="text-xs text-gray-500">2024-03-15</p>
            </div>
            <span class="text-xs bg-success/20 text-success px-3 py-1 rounded-full">已接种</span>
        </div>
        <div class="flex items-center justify-between p-3 bg-success/5 rounded-lg">
            <div>
                <p class="font-medium text-gray-800">六联疫苗</p>
                <p class="text-xs text-gray-500">2024-02-20</p>
            </div>
            <span class="text-xs bg-success/20 text-success px-3 py-1 rounded-full">已接种</span>
        </div>
        <div class="flex items-center justify-between p-3 bg-warning/5 rounded-lg">
            <div>
                <p class="font-medium text-gray-800">驱虫药</p>
                <p class="text-xs text-gray-500">下次: 2024-05-01</p>
            </div>
            <span class="text-xs bg-warning/20 text-warning px-3 py-1 rounded-full">待接种</span>
        </div>
    </div>
</div>

<div class="glass-card rounded-card p-4 mb-16 shadow-card">
    <h3 class="font-semibold text-gray-800 mb-3"><i class="fas fa-notes-medical text-primary mr-2"></i>就诊记录</h3>
    <div class="space-y-3">
        <div class="p-3 bg-gray-50 rounded-lg">
            <div class="flex justify-between items-start mb-2">
                <p class="font-medium text-gray-800">常规体检</p>
                <span class="text-xs text-gray-400">2024-03-10</span>
            </div>
            <p class="text-sm text-gray-600">体检结果正常，建议继续保持运动</p>
            <p class="text-xs text-gray-500 mt-1">宠物医院 · 李医生</p>
        </div>
        <div class="p-3 bg-gray-50 rounded-lg">
            <div class="flex justify-between items-start mb-2">
                <p class="font-medium text-gray-800">皮肤检查</p>
                <span class="text-xs text-gray-400">2024-01-15</span>
            </div>
            <p class="text-sm text-gray-600">轻微皮肤过敏，已开药</p>
            <p class="text-xs text-gray-500 mt-1">宠物医院 · 王医生</p>
        </div>
    </div>
</div>
`;

// 我的页面内容
const profilePage = `
<div class="flex justify-between items-center mb-4 px-1">
    <h1 class="text-xl font-bold text-gray-800">我的</h1>
    <button class="text-gray-600">
        <i class="fas fa-cog text-xl"></i>
    </button>
</div>

<div class="glass-card rounded-card p-4 mb-4 shadow-card">
    <div class="flex items-center gap-4">
        <img src="https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&h=150&fit=crop" 
             class="w-16 h-16 rounded-full object-cover border-2 border-white shadow-sm">
        <div class="flex-1">
            <h2 class="text-lg font-bold text-gray-800">铲屎官</h2>
            <p class="text-sm text-gray-500">ID: 1234567890</p>
            <div class="flex gap-2 mt-1">
                <span class="text-xs bg-primary/10 text-primary px-2 py-0.5 rounded-full">VIP会员</span>
            </div>
        </div>
        <i class="fas fa-chevron-right text-gray-400"></i>
    </div>
</div>

<div class="glass-card rounded-card p-3 mb-3 shadow-card">
    <div class="grid grid-cols-4 gap-3 text-center">
        <div>
            <p class="text-xl font-bold text-gray-800">1</p>
            <p class="text-xs text-gray-500">宠物</p>
        </div>
        <div>
            <p class="text-xl font-bold text-gray-800">16</p>
            <p class="text-xs text-gray-500">设备</p>
        </div>
        <div>
            <p class="text-xl font-bold text-gray-800">365</p>
            <p class="text-xs text-gray-500">使用天数</p>
        </div>
        <div>
            <p class="text-xl font-bold text-gray-800">28</p>
            <p class="text-xs text-gray-500">联动场景</p>
        </div>
    </div>
</div>

<div class="glass-card rounded-card p-3 mb-3 shadow-card">
    <div class="space-y-1">
        <div class="flex items-center justify-between p-3 hover:bg-gray-50 rounded-lg cursor-pointer">
            <div class="flex items-center gap-3">
                <i class="fas fa-paw text-primary text-lg w-6"></i>
                <span class="text-gray-800">我的宠物</span>
            </div>
            <i class="fas fa-chevron-right text-gray-400"></i>
        </div>
        <div class="flex items-center justify-between p-3 hover:bg-gray-50 rounded-lg cursor-pointer">
            <div class="flex items-center gap-3">
                <i class="fas fa-microchip text-secondary text-lg w-6"></i>
                <span class="text-gray-800">设备管理</span>
            </div>
            <i class="fas fa-chevron-right text-gray-400"></i>
        </div>
        <div class="flex items-center justify-between p-3 hover:bg-gray-50 rounded-lg cursor-pointer">
            <div class="flex items-center gap-3">
                <i class="fas fa-link text-success text-lg w-6"></i>
                <span class="text-gray-800">联动场景</span>
            </div>
            <i class="fas fa-chevron-right text-gray-400"></i>
        </div>
    </div>
</div>

<div class="glass-card rounded-card p-3 mb-3 shadow-card">
    <div class="space-y-1">
        <div class="flex items-center justify-between p-3 hover:bg-gray-50 rounded-lg cursor-pointer">
            <div class="flex items-center gap-3">
                <i class="fas fa-bell text-warning text-lg w-6"></i>
                <span class="text-gray-800">消息通知</span>
            </div>
            <div class="flex items-center gap-2">
                <span class="bg-red-500 text-white text-xs px-1.5 rounded-full">3</span>
                <i class="fas fa-chevron-right text-gray-400"></i>
            </div>
        </div>
        <div class="flex items-center justify-between p-3 hover:bg-gray-50 rounded-lg cursor-pointer">
            <div class="flex items-center gap-3">
                <i class="fas fa-shield-alt text-primary text-lg w-6"></i>
                <span class="text-gray-800">隐私设置</span>
            </div>
            <i class="fas fa-chevron-right text-gray-400"></i>
        </div>
        <div class="flex items-center justify-between p-3 hover:bg-gray-50 rounded-lg cursor-pointer">
            <div class="flex items-center gap-3">
                <i class="fas fa-question-circle text-secondary text-lg w-6"></i>
                <span class="text-gray-800">帮助中心</span>
            </div>
            <i class="fas fa-chevron-right text-gray-400"></i>
        </div>
        <div class="flex items-center justify-between p-3 hover:bg-gray-50 rounded-lg cursor-pointer">
            <div class="flex items-center gap-3">
                <i class="fas fa-info-circle text-gray-500 text-lg w-6"></i>
                <span class="text-gray-800">关于我们</span>
            </div>
            <i class="fas fa-chevron-right text-gray-400"></i>
        </div>
    </div>
</div>

<div class="glass-card rounded-card p-3 mb-16 shadow-card">
    <button class="w-full py-3 text-red-500 font-medium">
        <i class="fas fa-sign-out-alt mr-2"></i>退出登录
    </button>
</div>
`;

// 页面切换函数
function switchPage(pageIndex) {
    const pages = [homePage, devicesPage, healthPage, profilePage];
    const tabs = document.querySelectorAll('.tab-item');
    const content = document.getElementById('appContent');
    
    tabs.forEach((tab, index) => {
        if (index === pageIndex) {
            tab.classList.remove('text-gray-400');
            tab.classList.add('text-primary');
            tab.querySelector('span').classList.add('font-medium');
        } else {
            tab.classList.remove('text-primary');
            tab.classList.add('text-gray-400');
            tab.querySelector('span').classList.remove('font-medium');
        }
    });
    
    content.innerHTML = pages[pageIndex];
    content.scrollTop = 0;
}

document.addEventListener('DOMContentLoaded', () => {
    switchPage(0);
});
