# Simple Health Bar

## Description
This Godot plugin provides a **health bar with a damage indicator**. When health decreases, the red progress bar updates immediately, while the white damage bar updates with a **0.2-second delay** (modifiable in the Timer node within the plugin scene). This delay helps visually indicate recent damage taken, making health loss more noticeable.

## Features
- A responsive progress bar that instantly reflects health changes.
- A secondary damage bar that updates after a short delay to highlight recent damage.

## Usage
1. Call `init_bar(health_value)` in the `ready()` function of the script where you want to attach the health bar to.
2. Call `update_bar(new_health_value)` whenever the health value changes.

## License
This plugin is open-source and licensed under the MIT License. See `LICENSE.md` for details.



### 简单健康条

#### 描述
这个Godot插件提供了一个**带有伤害指示器的健康条**。当健康值减少时，红色进度条立即更新，而白色伤害条则以**0.2秒的延迟**更新（可在插件场景内的计时器节点中修改）。这种延迟有助于直观地显示最近受到的伤害，使健康值的减少更明显。

#### 特点
- 一个响应迅速的进度条，能立即反映健康值的变化。
- 一个次要伤害条，在短延迟后更新以突出显示最近的伤害。

#### 使用方法
1. 在你想要附加健康条的脚本的`ready()`函数中调用`init_bar(health_value)`。
2. 每当健康值变化时调用`update_bar(new_health_value)`。

#### 许可证
这个插件是开源的，根据MIT许可证授权。详情见`LICENSE.md`。