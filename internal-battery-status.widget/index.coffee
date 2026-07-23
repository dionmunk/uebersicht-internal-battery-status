command: "pmset -g batt"

refreshFrequency: '10s'

style: """
  // grid: col 2 · row 1 · 1×1  (see LAYOUT.md)
  top 10px
  left 340px

  color var(--text, #fff)
  text-shadow: 0 1px 1px rgba(20, 1, 1, 0.10)   // inherits to all text elements
  font-family -apple-system, BlinkMacSystemFont, system-ui, sans-serif
  display: flex
  gap: 10px

  .panel
    background var(--panel-bg, rgba(#000, .15))
    -webkit-backdrop-filter: blur(var(--panel-blur, 48px))
    backdrop-filter: blur(var(--panel-blur, 48px))
    border-radius 10px
    box-sizing: border-box
    min-height: 80px       // base minimum widget height (see LAYOUT.md)

  .panel-stats
    padding 10px 10px 12px
    display: flex          // lets stats-inner fill the 80px panel height

  .stats-inner
    width: 300px
    text-align: left
    position: relative
    display: flex
    flex-direction: column   // title on top, numbers + bar pushed to the bottom

  .widget-title
    font-size 10px
    text-transform uppercase
    font-weight bold

  .stats-container
    margin-top: auto       // push the numbers + bar to the panel bottom
    margin-bottom 5px      // gap between the labels and the bar
    border-collapse collapse
    table-layout: fixed

  td
    font-size: 14px
    font-weight: 300
    text-align: left
    overflow: hidden
    white-space: nowrap
    text-overflow: ellipsis

  // Space between the numbers and their labels below them.
  .stat
    padding-bottom: 4px

  .label
    font-size 8px
    text-transform uppercase
    font-weight bold

  .state-text
    text-transform: capitalize

  // Three columns of equal share — keeps spacing consistent with the other widgets.
  // State on the left, remaining in the middle, level on the far right.
  .col-percent,
  .col-state,
  .col-remaining
    width: 33%

  .col-state
    text-align: left

  .col-remaining
    text-align: center

  .col-percent
    text-align: right

  .bar-container
    width: 100%
    height: 6px
    border-radius: 6px
    background: var(--level-base, rgba(#fff, .2))
    position: relative
    box-shadow: 0 1px 1px rgba(20, 1, 1, 0.10)   // base bar: matches text shadow

  // Single left-anchored layer (same pattern as the multi-layer bars).
  .bar
    position: absolute
    left: 0
    top: 0
    height: 6px
    border-radius: 6px
    transition: width .2s ease-in-out, background .6s ease
    box-shadow: 1px 0 3px rgba(0, 0, 0, 0.04)   // faint separation under the cap

  // Charge bar colored by battery level (green healthy → red low) under a color
  // scheme; under monochrome each status falls through to --level-max (mode-driven
  // ink, so it flips with light/dark) — level is still shown by the bar width.
  .bar-charge
    background: var(--level-max, rgba(#fff, 1))
  .bar-charge.status-ok
    background: var(--status-ok, var(--level-max, rgba(#fff, 1)))
  .bar-charge.status-warn
    background: var(--status-warn, var(--level-max, rgba(#fff, 1)))
  .bar-charge.status-elevated
    background: var(--status-elevated, var(--level-max, rgba(#fff, 1)))
  .bar-charge.status-critical
    background: var(--status-critical, var(--level-max, rgba(#fff, 1)))
"""

render: -> """
  <div class="panel panel-stats">
    <div class="stats-inner">
      <div class="widget-title">Internal Battery</div>
      <table class="stats-container" width="100%">
        <tr>
          <td class="stat col-state"><span class="state-text"></span></td>
          <td class="stat col-remaining"><span class="remaining"></span></td>
          <td class="stat col-percent"><span class="percent"></span></td>
        </tr>
        <tr>
          <td class="label col-state">state</td>
          <td class="label col-remaining"><span class="remaining-label"></span></td>
          <td class="label col-percent">level</td>
        </tr>
      </table>
      <div class="bar-container">
        <div class="bar bar-charge"></div>
      </div>
    </div>
  </div>
"""

update: (output, domEl) ->
  # pmset line looks like: "100%; charged; 0:00 remaining present: true"
  m = output.match /(\d+)%;\s*([\w ]+?);(?:\s*([0-9]+:[0-9]+|\(no estimate\)))?/
  return unless m

  percent      = parseInt(m[1], 10)
  state        = m[2].trim().toLowerCase()
  remaining    = (m[3] or '').trim()
  hasRemaining = remaining not in ['', '0:00', '(no estimate)']

  div = $(domEl)

  # On AC but not actively charging (e.g. held at a charge limit) — treat as charged.
  state = 'charged' if state is 'ac attached'

  div.find('.percent').text "#{percent}%"
  div.find('.state-text').text state
  div.find('.remaining').text(if hasRemaining then remaining else '')
  div.find('.remaining-label').text(if hasRemaining then 'remaining' else '')
  div.find('.bar-charge').css "width", "#{percent}%"

  # Bar color reflects the charge level — the inverse of Storage's fill scale
  # (a low battery is the severe end, like a full disk is for storage).
  level =
    if percent <= 10 then 'status-critical'
    else if percent <= 25 then 'status-elevated'
    else if percent <= 40 then 'status-warn'
    else 'status-ok'
  div.find('.bar-charge')
    .removeClass('status-ok status-warn status-elevated status-critical')
    .addClass(level)

  # Re-show the widget if it was previously hidden.
  div.show(1).animate({opacity: 1}, 250, 'swing')
