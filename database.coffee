_ = require 'lodash'
when_ = require 'when'

wordsKey = () -> '[[APP-wordbank]]::stefano@stefanomasini.com::words'

exports.buildDatabase = (redisDb) ->
    saveChanges: (changes) ->
        if changes.length == 0
            return when_.resolve()
        changesDict = _.zipObject([c.src, JSON.stringify(c)] for c in changes)
        redisDb.hmset wordsKey(), changesDict

    deleteWords: (words) ->
        if words.length == 0
            return when_.resolve()
        redisDb.hdel wordsKey(), words

    getWords: () ->
        redisDb.hgetall(wordsKey())
            .then (res) ->
                return (JSON.parse(v) for v in _.values(res))
