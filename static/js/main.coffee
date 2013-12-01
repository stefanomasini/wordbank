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
            if saving.changes.length == 0 and saving.deletes.length == 0
                scheduleNextAjaxSave()
                return
            $('.saving-status').hide()
            $('.saving-status-up').show()
            $.ajax
                type: 'POST'
                url: 'changes'
                data:
                    data: JSON.stringify
                        changes: saving.changes
                        deletes: saving.deletes
            .done () ->
                $('.saving-status').hide()
                $('.saving-status-ok').show().fadeOut()
                scheduleNextAjaxSave()
            .fail () ->
                $('.saving-status').hide()
                $('.saving-status-warning').show()
                saving.revert()
                scheduleNextAjaxSave()


        scheduleNextAjaxSave = () ->
            setTimeout saveViaAjax, saveTimeoutInMs

        scheduleNextAjaxSave()


        # -- UI -------

        updateCounters = () ->
            $('.num-words').text(bank.getAllTranslatedWords().length)
            $('.num-unknown-words').text(bank.getAllNewWords().length)

            allWords = learning.getWordProbabilities(bank.getAllTranslatedWords())
            allWords = _.sortBy(allWords, (wp) -> wp.word.getWord())
            $('.all-words').empty()
            numWords = 0
            numKnownWords = 0
            for wp in allWords
                if wp.fromSource
                    numWords += 1
                    if wp.word.isKnownBothWays()
                        numKnownWords += 1
                    $('.all-words').append("""
                        <tr style="background-color: #{if wp.word.isKnownBothWays() then '#D9FFD5' else '#FFEFE1'};" data-word="#{wp.word.getWord()}">
                            <td>#{numWords}</td>
                            <td class="source-word">#{wp.word.getWord()}</td>
                            <td class="table-word-translation">#{wp.word.getTranslation()}</td>
                            <td>#{Math.floor(wp.weight*100)}</td>
                            <td>#{wp.word.getMemorizationAttempts(true).length} + #{wp.word.getMemorizationAttempts(false).length}</td>
                            <td>#{wp.word.getNumSuccessfulMemorizationAttempts(true)} + #{wp.word.getNumSuccessfulMemorizationAttempts(false)}</td>
                        </tr>
                    """)
            percKnown = Math.floor(100*numKnownWords/numWords)
            $('.bar-words-known').css('width', "#{percKnown}%")
            $('.bar-words-unknown').css('width', "#{100-percKnown}%")
            $('.perc-known').text("#{percKnown}%")

            allNewWords = bank.getAllNewWords()
            allNewWords = _.sortBy(allNewWords, (w) -> w.getWord())
            $('.all-new-words').empty()
            for word, wordIdx in allNewWords
                $('.all-new-words').append("""
                    <tr data-word="#{word.getWord()}">
                        <td>#{wordIdx}</td>
                        <td class="source-word">#{word.getWord()}</td>
                        <td><input type="text" class="form-control new-word-translation" placeholder="Translation"></td>
                    </tr>
                """)

        editOnClick = (selector, callback) ->
            $('.container').on 'click', selector, () ->
                srcWord = $(this).parents('tr').data('word')
                cellTag = $(this)
                oldText = cellTag.text()
                cellTag.empty().append """<input type="text" class="form-control" value="#{oldText}">"""
                cellTag.find('input').click (e) ->
                    e.preventDefault()
                    return false
                cellTag.find('input').focus().select().change () ->
                    callback(srcWord, $(this).val())
                restore = () -> cellTag.empty().text(oldText)
                cellTag.find('input').focusout () -> restore()
                cellTag.find('input').keyup (e) ->
                    if e.keyCode == 27
                        restore()
                    if e.keyCode == 13
                        $(this).focusout()

        editOnClick '.source-word', (srcWord, newSource) ->
            if newSource == ''
                bank.removeWord(srcWord)
            else
                bank.renameWord(srcWord, newSource)
            updateCounters()

        editOnClick '.table-word-translation', (srcWord, newTranslation) ->
            if newTranslation != ''
                bank.setTranslation(srcWord, newTranslation)
                updateCounters()

        $('.container').on 'change', '.new-word-translation', () ->
            bank.setTranslation($(this).parents('tr').data('word'), $(this).val())
            updateCounters()

        # ----------

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

            $('#word-buttons').children().show()

        showTranslation = () ->
            $('.word-under-test').text(currentWord.getWord()).show()
            $('.word-translation').text(currentWord.getTranslation()).show()
            $('#word-buttons').children().hide()
            translationShown = true

        hideTranslation = () ->
            $('.word-translation').text('?')
            translationShown = false

        $('.word-translation').on 'click', () ->
            if translationShown
                hideTranslation()
                fetchNextWord()

        $('.word-under-test').on 'click', () ->
            if translationShown
                hideTranslation()
                fetchNextWord()

        $('#btn-iknow').on 'click', (e) ->
            if currentWord
                currentWord.attemptMemorization(true, currentFromSource)
                updateCounters()
                fetchNextWord()

        $('#btn-idontknow').on 'click', (e) ->
            if currentWord
                currentWord.attemptMemorization(false, currentFromSource)
                updateCounters()
                showTranslation()

        $('#vocabulary').on 'click', () ->
            $('#vocabulary-section').show()
            $('#exercise-section').hide()
            updateCounters()

        $('#close-vocabulary').on 'click', () ->
            $('#vocabulary-section').hide()
            $('#exercise-section').show()



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
