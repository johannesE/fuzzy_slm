
doGraphStuff = ->
  tick = ->
    link.attr("x1", (d) ->
      d.source.x
    ).attr("y1", (d) ->
      d.source.y
    ).attr("x2", (d) ->
      d.target.x
    ).attr "y2", (d) ->
      d.target.y
    linktext.attr "x", (d) ->
      (d.source.x + d.target.x) / 2 - 10
    .attr "y", (d) ->
      (d.source.y + d.target.y) / 2 - 4
    node.attr "transform", (d) ->
      "translate(" + d.x + "," + d.y + ")"

    return
  dblclick = (d) ->
    d3.select(this).classed "fixed", d.fixed = false
    return
  dragstart = (d) ->
    d3.select(this).classed "fixed", d.fixed = true
    return
  console.log "started to draw the graph"
  width = 1000
  height = 500
  force = d3.layout.force().size([
    width
    height
  ]).charge(-400).linkDistance(50).on("tick", tick)
  drag = force.drag().on("dragstart", dragstart)
  svg = d3.select(".graph").append("svg").attr("width", width).attr("height", height)
  link = svg.selectAll(".link")
  node = svg.selectAll(".node")
  linktext = svg.selectAll(".text")
  blubb = ->
    nodesD = $('.graph').data('nodes')
    linksD = $('.graph').data('links')

    force.nodes(nodesD).links(linksD).start()
    link = link.data(linksD).enter().append("line").attr("class", "link")
    linktext =linktext.data(linksD).enter().append("text")
    .attr("dx", 12)
    .attr("dy", ".35em")
    .attr("class", "text")
    .text((d) -> d.tight + ", "+ d.loose)
    node = node.data(nodesD).enter().append("g").attr("class", "node")
    .on("dblclick", dblclick).call(drag)

    node.append("circle").attr("r", 12).attr("x", -6).attr("y", -6)
    node.append("text")
    .attr("dx", 12)
    .attr("dy", ".35em")
    .text((d) -> d.name)

    return

  blubb()
  console.log "ended to draw the graph"
  return

$(document).on('page:load', doGraphStuff())