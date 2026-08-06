command: "internal-battery-status.widget/lib/battery.sh"

# Enable or disable this widget.
widgetEnabled: true   # true | false

refreshFrequency: '10s'

style: """
  // grid: col 1 · row 8 · 1×1, below the top-battery widget (see LAYOUT.md)
  // top = 634 (top-battery's top) + 122 (its real height) + 10 (gap)
  top 766px
  left 10px

  color var(--text, #fff)
  text-shadow: 0 1px 1px rgba(20, 1, 1, 0.2)   // inherits to all text elements
  font-family -apple-system, BlinkMacSystemFont, system-ui, sans-serif
  display: flex
  gap: 10px

  .panel
    background var(--panel-bg, rgba(#000, .15))
    -webkit-backdrop-filter: blur(var(--panel-blur, 48px))
    backdrop-filter: blur(var(--panel-blur, 48px))
    border-radius 10px
    box-sizing: border-box
    min-height: var(--grid-unit, 80px)       // base minimum widget height (see LAYOUT.md)

  .panel-stats
    padding 10px 10px 12px
    display: flex          // lets stats-inner fill the 80px panel height

  .stats-inner
    width: calc(var(--grid-col, 320px) - 20px)
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

  // Charging bolt shown only while charging (toggled in update); green to match
  // the charging bar. The SF Symbol bolt.fill, rendered to a PNG on first run
  // (lib/render-bolt.swift) and used as a mask so it takes the theme colour.
  .charge-bolt
    display: none
    width: 10px
    height: 14px
    margin-left: 4px
    vertical-align: -2px
    background: var(--status-ok, var(--green, #34C759))
    -webkit-mask-image: url(internal-battery-status.widget/lib/icons/bolt.fill.ink.png)
    -webkit-mask-repeat: no-repeat
    -webkit-mask-position: center
    -webkit-mask-size: contain
    mask-image: url(internal-battery-status.widget/lib/icons/bolt.fill.ink.png)
    mask-repeat: no-repeat
    mask-position: center
    mask-size: contain

  .charge-bolt.on
    display: inline-block

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
          <td class="stat col-state"><span class="state-text"></span><span class="charge-bolt"></span></td>
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
  # Hide entirely when disabled.
  if not @widgetEnabled
    $(domEl).css('display', 'none')
    return
  $(domEl).css('display', '')
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
  div.find('.charge-bolt').toggleClass('on', state is 'charging')
  div.find('.remaining').text(if hasRemaining then remaining else '')
  div.find('.remaining-label').text(if hasRemaining then 'remaining' else '')
  div.find('.bar-charge').css "width", "#{percent}%"

  # Charging shows a green bar to signal it's filling up (even on a low battery);
  # otherwise the color reflects the charge level — the inverse of Storage's fill
  # scale (a low battery is the severe end, like a full disk is for storage).
  level =
    if state is 'charging' then 'status-ok'
    else if percent <= 10 then 'status-critical'
    else if percent <= 25 then 'status-elevated'
    else if percent <= 40 then 'status-warn'
    else 'status-ok'
  div.find('.bar-charge')
    .removeClass('status-ok status-warn status-elevated status-critical')
    .addClass(level)

  # Re-show the widget if it was previously hidden.
  div.show(1).animate({opacity: 1}, 250, 'swing')
