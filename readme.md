

## 1) 价格产生（`order_generator.v`）

* 用两个 16-bit LFSR 生成伪随机数（内部有 `div` 分频，让数值变化更慢，便于板上观察）。
* 映射为 8-bit 价格：`buy_price = 50 + lfsr1[4:0]`、`sell_price = 55 + lfsr2[4:0]`（范围大致 50–81、55–86）。

## 2) 撮合引擎（`matching_engine_8.v`）

* 维护**8 级移位寄存器**的买/卖价窗口：每拍把新价格推进 `buy_q0/sell_q0`，旧值后移到 `q7`。
* 组合逻辑求：`best_bid = max(buy_q0..buy_q7)`、`best_ask = min(sell_q0..sell_q7)`。
* 生成：

  * `match_flag = (best_bid >= best_ask)`（并排除无效边界：买=0、卖=0xFF）。
  * `trade_price = (best_bid + best_ask) >> 1`（中点价）。

## 3) 控制器 FSM（`controller_fsm.v`）

* 三态：`IDLE` / `MATCH` / `HALT`。
* 转移由 `match_flag` 和 `halt_flag` 决定；在 `MATCH` 态输出 `enable_count=1`，其余为 0。

## 4) 成交计数（`counter.v`）

* 在 `enable_count & match_flag & !halt_flag` 时，`trade_count` 自增。
* 达到阈值（`MAX_TRADES=100`）置位 `halt_flag=1`，系统进入停机态。

## 5) 价差计算（`spread_accumulator.v`）

* 在 `enable_count & match_flag` 时计算**当前一拍的价差**：`spread_now = buy_price - sell_price`（按你现有代码是“本拍差值”，非累加和）。

## 6) 板上显示（`display.v`）

* HEX 显示（低位在 HEX0）：

  * `HEX1:HEX0 = buy_price`
  * `HEX3:HEX2 = sell_price`
  * `HEX5:HEX4 = spread_now`
* LED 指示：

  * `LEDR[0] = match_flag`（有成交就亮/闪）
  * `LEDR[1] = halt_flag`（到阈值停机）
  * `LEDR[3:2] = state`（FSM 状态位）
  * `LEDR[9:4] = trade_count[5:0]`

## 7) 顶层集成（`system_top.v`）

* 时钟：`CLOCK_50` 作为全局时钟；`KEY[0]` 低有效，翻转成模块内部的高有效 `reset`。
* 串起 1→2→3→4→5→6 的信号通路，在板上即可看到价格、撮合与状态随时间变化。

**一句话**：
每拍产生一组买/卖价 → 写入 8 深度窗口 → 取最高买/最低卖判断是否成交 → 成交则计数，达到门限停机 → 价格/价差/状态实时上屏与点灯。
s
