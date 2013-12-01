when_ = require 'when'

exports.configureApp = (app, appConf) ->
    app.post '/changes', 'changes', (req, res) ->
        data = JSON.parse(req.param('data'))
        deletes = data.deletes
        when_.all([appConf.db.saveChanges(data.changes), appConf.db.deleteWords(deletes)])
            .then () ->
                res.json
                    status: 'ok'

    app.get '/words', 'words', (req, res) ->
        appConf.db.getWords()
            .then (words) ->
                    res.json
                        words: words
