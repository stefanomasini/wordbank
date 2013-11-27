_ = require 'lodash'

wordsKey = () -> '[[APP-wordbank]]::stefano@stefanomasini.com::words'

exports.buildDatabase = (redisDb) ->
    saveChanges: (changes) ->
        changesDict = _.zipObject([c.src, JSON.stringify(c)] for c in changes)
        redisDb.hmset wordsKey(), changesDict

    getWords: () ->
        redisDb.hgetall(wordsKey())
            .then (res) ->
                return (JSON.parse(v) for v in _.values(res))
