define ['jquery', 'cs!js/bank'], ($, bankMod) ->

    $(document).ready () ->
        bank = new bankMod.Bank()
        learning = new bankMod.Learning(bank)
        currentWord = null
        translationShown = false

        $('#newword').on 'change', () ->
            bank.addNewWord($(this).val())

        $('#newword-translation').on 'change', () ->
            bank.setTranslation($('#newword').val(), $(this).val())
            $(this).val('')
            $('#newword').val('')
            $('#newword').focus()

        $('#save-new-word').on 'click', (e) ->
            e.preventDefault()

            fetchNextWord()

        fetchNextWord = () ->
            currentWord = learning.fetchNext()
            if currentWord
                $('.word-under-test').text(currentWord.getWord())

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

        $('.word-translation').on 'click', () ->
            $(this).hide()
            translationShown = false
            fetchNextWord()

        $('.word-under-test').on 'click', () ->
            $('.word-translation').hide()
            translationShown = false
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
        fetchNextWord()

