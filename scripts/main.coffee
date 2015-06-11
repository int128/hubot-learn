# Description:
#   A just foolish bot
#
# Commands:
#   hubot - Invoke hubot process

kuromoji = require 'kuromoji'

class Tokenizer
  constructor: ->
    kuromoji
    .builder(dicPath: 'node_modules/kuromoji/dist/dict/')
    .build (err, tokenizer) => @tokenizer = tokenizer

  tokenize: (text) ->
    if @tokenizer then @tokenizer.tokenize text

class Brain
  constructor: (brain, random) ->
    @_brain = brain
    @_random = random

  _randomOrEmpty: (list) -> @_random(list) or ''
  _getWordsOfKind: (pos) -> @_brain.get(pos) or []

  _findWordOf: (pos...) ->
    @_randomOrEmpty @_getWordsOfKind @_random pos

  _findKnownWordIn: (words, pos...) ->
    known = @_getWordsOfKind @_random pos
    @_randomOrEmpty words.filter (word) -> word in known

  learn: (tokens) ->
    tokens.forEach (token) =>
      known = @_getWordsOfKind token.pos
      known.push token.surface_form
      @_brain.set token.pos, known

  say: (tokens) ->
    filtered = tokens.filter (token) -> token.pos == '名詞' and token.surface_form.length > 1
    words = filtered.map (token) -> token.surface_form
    topic = @_findKnownWordIn words, '名詞'

    [
      @_findWordOf '形容詞'
      topic
      @_findWordOf '助詞'
      @_findWordOf '名詞'
      @_findWordOf '助詞'
      @_findWordOf '副詞'
      @_findWordOf '動詞', '助動詞'
    ].join('') if topic

tokenizer = new Tokenizer()

module.exports = (robot) ->
  robot.hear /(.+)/, (msg) ->
    brain = new Brain(robot.brain, msg.random)
    tokens = tokenizer.tokenize msg.message.text
    if tokens
      saying = brain.say tokens
      msg.send saying if saying
      brain.learn tokens