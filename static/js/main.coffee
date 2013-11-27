define ['jquery', 'cs!js/bank'], ($, bankMod) ->

    $(document).ready () ->
        bank = new bankMod.Bank()
        learning = new bankMod.Learning(bank)
        currentWord = null
        translationShown = false

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
            [currentWord, fromSource] = learning.fetchNext()
            if currentWord
                if fromSource
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
                currentWord.attemptMemorization(true)
                fetchNextWord()

        $('#btn-iknow-but-show').on 'click', (e) ->
            if currentWord
                currentWord.attemptMemorization(true)
                showTranslation()

        $('#btn-idontknow').on 'click', (e) ->
            if currentWord
                currentWord.attemptMemorization(false)
                showTranslation()

        bank.setTranslation('begrijpen', 'capire')
        bank.setTranslation('tafel', 'tavolo')
        updateCounters()
        fetchNextWord()

