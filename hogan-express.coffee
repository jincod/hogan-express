###!
 * Copyright (c) 2012 Andrew Volkov <hello@vol4ok.net>
###

$ = {}
$ extends require 'fs'
$ extends require 'util'
$ extends require 'path'
hogan = require 'hogan.js'

cache = {}
ctx = {}

read = (path, options, fn) ->
  str = cache[path]
  return fn(null, str) if (options.cache and str)
  $.readFile path, 'utf8', (err, str) ->
    return fn(err) if (err)
    cache[path] = str if (options.cache)
    fn(null, str)

renderPartials = (partials, opt, fn) ->
  count = 1
  result = {}
  for name, path of partials
    continue unless typeof path is 'string'
    path += ctx.ext unless $.extname(path) 
    path = ctx.lookup(path)
    count++
    read path, opt, ((name, path) ->
        return (err, str) ->
          return unless count
          if err
            count = 0
            fn(err)
          result[name] = str
          fn(null, result) unless --count
      )(name, path)
  fn(null, result) if --count

renderLayout = (path, opt, fn) ->
  return fn(null, false) unless path
  path += ctx.ext unless $.extname(path) 
  path = ctx.lookup(path)
  return fn(null, false) unless path
  read path, opt, (err, str) ->
    return fn(err) if (err)
    fn(null, str)

render = (path, opt, fn) ->
  ctx = this
  partials = opt.settings.partials or {}
  partials = partials extends opt.partials if opt.partials
  renderPartials partials, opt, (err, partials) ->
    return fn(err) if (err)
    renderLayout opt.layout or opt.settings.layout, opt, (err, layout) ->
      read path, opt, (err, str) ->
        return fn(err) if (err)
        try
          tmpl = hogan.compile(str, opt)
          result = tmpl.render(opt.locals, partials)
          if layout
            opt.locals.yield = result
            tmpl = hogan.compile(layout, opt)
            result = tmpl.render(opt.locals, partials)
          fn(null, result)            
        catch err
          fn(err)

module.exports = render