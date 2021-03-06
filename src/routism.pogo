variable regex = r/(\:([a-z\-_]+))/ig
splat variable regex = r/(\:([a-z\-_]+)\\\*)/ig

escape regex (pattern) = pattern.replace r/[-\/\\^$*+?.()|[\]{}]/g '\$&'

exports.table () =
  rows = []
  {
    add (pattern, route) =
      rows.push {
        pattern = pattern
        route = route
      }

    compile () = exports.compile (rows)
  }

exports.compile (route table) =
  groups = []
  regexen = []
  for each @(row) in (route table)
    add group for (row) to (groups)
    regexen.push "(#(compile(row.pattern)))"

  {
    regex = new (RegExp ("^(#(regexen.join('|')))$"))

    groups = groups

    recognise (input) =
      recognise (self.regex.exec(input) || []) in (self.groups)
  }

add group for (row) to (groups) =
  group = { route = row.route, params = [] }
  groups.push (group)
  add variables in (row.pattern) to (group)

add variables in (pattern) to (group) =
  while (match = variable regex.exec(pattern))
    group.params.push (match.2)

compile (pattern) =
  escape regex (pattern) \
  .replace (splat variable regex, "(.+)") \
  .replace (variable regex, "([^\/]+)")

exports.compile pattern (pattern) =
  compile (pattern)

recognise (match) in (groups) =
  g = 0
  for (i = 2, i < match.length, i := i + groups.(g - 1).params.length + 1)
    if (typeof(match.(i)) != 'undefined')
      return {
        route = groups.(g).route
        params = extract params for (groups.(g)) from (match) after (i)
      }

    g := g + 1

  false

extract params for (group) from (match) after (i) =
  params = []
  for (p = 0, p < group.params.length, p := p + 1)
    params.push [group.params.(p), decodeURIComponent(match.(p + i + 1))]

  params
