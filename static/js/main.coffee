define ['jquery', 'cs!js/bank'], ($, bankMod) ->

    $(document).ready () ->
        saver = new bankMod.Saver()
        bank = new bankMod.Bank (change) -> saver.notify(change)
        learning = new bankMod.Learning(bank)
        currentWord = null
        currentFromSource = null
        translationShown = false

        saveTimeoutInMs = 1000

        # -- Saving -------

        saveViaAjax = () ->
            saving = saver.startSaving()
            if saving.changes.length == 0
                scheduleNextAjaxSave()
                return
            console.log('Attempting Ajax save...')
            $.ajax
                type: 'POST'
                url: 'changes'
                data:
                    data: JSON.stringify
                        changes: saving.changes
            .done () ->
                console.log('Saving done')
                scheduleNextAjaxSave()
            .fail () ->
                console.log('Ajax failed')
                saving.revert()
                scheduleNextAjaxSave()

        scheduleNextAjaxSave = () ->
            setTimeout saveViaAjax, saveTimeoutInMs

        scheduleNextAjaxSave()


        # -- UI -------

        updateCounters = () ->
            $('.num-words').text(bank.getAllTranslatedWords().length)

        $('#save-new-word').on 'click', (e) ->
            e.preventDefault()
            bank.setTranslation($('#newword').val(), $('#newword-translation').val())
            $('#newword').val('')
            $('#newword-translation').val('')
            $('#newword').focus()
            updateCounters()

        fetchNextWord = () ->
            [currentWord, currentFromSource] = learning.fetchNext()
            if currentWord
                if currentFromSource
                    $('.word-under-test').text(currentWord.getWord())
                    $('.word-translation').text('?')
                else
                    $('.word-under-test').text('?')
                    $('.word-translation').text(currentWord.getTranslation())

            allWords = learning.getWordProbabilities(bank.getAllTranslatedWords())
            allWords = _.sortBy(_.pairs(allWords), ([word, prob]) -> prob)
            $('.all-words').empty()
            for [word, prob] in allWords
                $('.all-words').append("<li>#{Math.floor(prob*100)}% - #{word}</li>")
            $('#word-buttons').show()

        showTranslation = () ->
            $('.word-under-test').text(currentWord.getWord()).show()
            $('.word-translation').text(currentWord.getTranslation()).show()
            $('#word-buttons').hide()
            translationShown = true

        hideTranslation = () ->
            $('.word-translation').text('?')
            translationShown = false

        $('.word-translation').on 'click', () ->
            hideTranslation()
            fetchNextWord()

        $('.word-under-test').on 'click', () ->
            hideTranslation()
            fetchNextWord()

        $('#btn-iknow').on 'click', (e) ->
            if currentWord
                currentWord.attemptMemorization(true, currentFromSource)
                fetchNextWord()

        $('#btn-iknow-but-show').on 'click', (e) ->
            if currentWord
                currentWord.attemptMemorization(true, currentFromSource)
                showTranslation()

        $('#btn-idontknow').on 'click', (e) ->
            if currentWord
                currentWord.attemptMemorization(false, currentFromSource)
                showTranslation()

        # -- Load words ----
#        bank.setTranslation('begrijpen', 'capire')
#        bank.setTranslation('tafel', 'tavolo')

        $.ajax
            type: 'GET'
            url: 'words'
        .done (data) ->
                bank.initialize(data.words)
                updateCounters()
                fetchNextWord()
