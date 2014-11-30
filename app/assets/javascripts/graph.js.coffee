$(document).ready ->
  tick = ->
    link.attr("x1", (d) ->
      d.source.x
    ).attr("y1", (d) ->
      d.source.y
    ).attr("x2", (d) ->
      d.target.x
    ).attr "y2", (d) ->
      d.target.y

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
  width = 960
  height = 500
  force = d3.layout.force().size([
    width
    height
  ]).charge(-400).linkDistance(50).on("tick", tick)
  drag = force.drag().on("dragstart", dragstart)
  svg = d3.select("#graph").append("svg").attr("width", width).attr("height", height)
  link = svg.selectAll(".link")
  node = svg.selectAll(".node")
  blubb = ->
    nodesD = [
      {
        x: 10
        y: 10
        name: "asdf"
      }
      {
        x: 20
        y: 20
        name: "asdf"
      }
      {
        x: 30
        y: 30
        name: "asdf"
      }
      {
        x: 40
        y: 40
        name: "asdf"
      }
      {
        x: 477
        y: 248
        name: "asdf"
      }
      {
        x: 425
        y: 207
        name: "asdf"
      }
      {
        x: 402
        y: 155
        name: "asdf"
      }
      {
        x: 369
        y: 196
        name: "asdf"
      }
      {
        x: 350
        y: 148
        name: "asdf"
      }
      {
        x: 539
        y: 222
        name: "asdf"
      }
      {
        x: 594
        y: 235
        name: "asdf"
      }
      {
        x: 582
        y: 185
        name: "asdf"
      }
      {
        x: 633
        y: 200
        name: "asdf"
      }
    ]
    linksD = [
      {
        source: 0
        target: 1
      }
      {
        source: 1
        target: 2
      }
      {
        source: 2
        target: 0
      }
      {
        source: 1
        target: 3
      }
      {
        source: 3
        target: 2
      }
      {
        source: 3
        target: 4
      }
      {
        source: 4
        target: 5
      }
      {
        source: 5
        target: 6
      }
      {
        source: 5
        target: 7
      }
      {
        source: 6
        target: 7
      }
      {
        source: 6
        target: 8
      }
      {
        source: 7
        target: 8
      }
      {
        source: 9
        target: 4
      }
      {
        source: 9
        target: 11
      }
      {
        source: 9
        target: 10
      }
      {
        source: 10
        target: 11
      }
      {
        source: 11
        target: 12
      }
      {
        source: 12
        target: 10
      }
    ]
    force.nodes(nodesD).links(linksD).start()
    link = link.data(linksD).enter().append("line").attr("class", "link")
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
