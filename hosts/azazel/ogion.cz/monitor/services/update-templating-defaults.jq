.templating.list |= (
    map(
    .
    *
    if $prefs[.name] != null then
      {"current": ({"selected": true} + $prefs[.name])}
    else
      {}
    end
  )
)
