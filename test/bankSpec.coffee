define ['js/bank'], (bankMod) ->


    describe 'bank', () ->
        bank = null

        beforeEach () ->
            bank = new bankMod.Bank()

        it 'can add new word', () ->
            expect(bank.getSize()).toEqual(0)
            bank.addNewWord('foo')
            expect(bank.getSize()).toEqual(1)

        it 'can list all new words', () ->
            bank.addNewWord('foo')
            bank.addNewWord('bar')
            bank.addNewWord('bar')
            expect(bank.getAllNewWords().length).toEqual(2)

        it 'can accept a word translation and remembers it', () ->
            bank.addNewWord('foo')
            bank.setTranslation('foo', 'fooTranslated')
            bank.setTranslation('bar', 'barTranslated')
            expect(bank.getTranslationFor('foo')).toEqual('fooTranslated')
            expect(bank.getTranslationFor('bar')).toEqual('barTranslated')
            expect(bank.getTranslationFor('other')).toBeUndefined()

        it 'can list all translated words', () ->
            bank.addNewWord('foo')
            bank.setTranslation('bar', 'barTranslated')
            bank.setTranslation('baz', 'bazTranslated')
            expect(bank.getAllTranslatedWords().length).toEqual(2)

        it 'returns clever word objects', () ->
            expect(bank.getWord('foo')).toBeUndefined()
            bank.setTranslation('foo', 'fooTranslated')
            expect(bank.getWord('foo')).toBeDefined()
            expect(bank.getWord('foo').getWord()).toEqual('foo')
            expect(bank.getWord('foo').getTranslation()).toEqual('fooTranslated')


    describe 'word', () ->
        bank = null
        word = null

        beforeEach () ->
            bank = new bankMod.Bank()
            bank.setTranslation('foo', 'fooTranslated')
            word = bank.getWord('foo')

        it 'feeds back into bank', () ->
            word.setTranslation('anotherTranslaction')
            expect(bank.getTranslationFor('foo')).toEqual('anotherTranslaction')

        it 'stores memorization attempts', () ->
            expect(word.getMemorizationAttempts().length).toEqual(0)
            word.attemptMemorization(true)
            expect(word.getMemorizationAttempts().length).toEqual(1)
            expect(word.getMemorizationAttempts()[0].success).toEqual(true)

        it 'evaluates the memorization level', () ->
            expect(word.getNumSuccessfulMemorizationAttempts()).toEqual(0)
            word.attemptMemorization(true)
            expect(word.getNumSuccessfulMemorizationAttempts()).toEqual(1)
            word.attemptMemorization(true)
            expect(word.getNumSuccessfulMemorizationAttempts()).toEqual(2)
            word.attemptMemorization(false)
            expect(word.getNumSuccessfulMemorizationAttempts()).toEqual(0)
            word.attemptMemorization(true)
            expect(word.getNumSuccessfulMemorizationAttempts()).toEqual(1)

        it 'can tell whether a word is known', () ->
            expect(word.isKnown()).toBeFalsy()
            word.attemptMemorization(true)
            expect(word.isKnown()).toBeTruthy()
            word.attemptMemorization(false)
            expect(word.isKnown()).toBeFalsy()
            word.attemptMemorization(true)
            expect(word.isKnown()).toBeTruthy()


    describe 'learning algorithm', () ->
        bank = null
        allWords = null
        learning = null

        beforeEach () ->
            bank = new bankMod.Bank()
            allWords = []
            for i in [1..10]
                bank.setTranslation("#{i}", "#{i}t")
                allWords.push(bank.getWord("#{i}"))
            learning = new bankMod.Learning(bank)

        it 'fetches a different word at every attempt', () ->
            lastWord = learning.fetchNext()
            for i in [1..20]
                nextWord = learning.fetchNext()
                expect(nextWord.getWord()).not.toEqual(lastWord.getWord())
                lastWord = nextWord

        it 'computes probability for each word to be chosen as next', () ->
            totalProbability = _.reduce _.values(learning.getWordProbabilities(bank.getAllTranslatedWords())), (a,b) -> a+b
            expect(Math.abs(totalProbability - 1)).toBeLessThan(0.00001)

        it 'splits probability equally between known and unknown words', () ->
            for word in allWords[..3]
                word.attemptMemorization(true)
            totalProbabilityForKnown = 0
            totalProbabilityForUnknown = 0
            for [word, probability] in _.pairs(learning.getWordProbabilities(bank.getAllTranslatedWords()))
                if bank.getWord(word).isKnown()
                    totalProbabilityForKnown += probability
                else
                    totalProbabilityForUnknown += probability
            expect(Math.abs(totalProbabilityForKnown - 0.5)).toBeLessThan(0.00001)
            expect(Math.abs(totalProbabilityForUnknown - 0.5)).toBeLessThan(0.00001)

        it 'makes lesser known words more likely to be chosen', () ->
            bank.getWord('1').attemptMemorization(true)
            bank.getWord('2').attemptMemorization(true)
            bank.getWord('2').attemptMemorization(true)
            bank.getWord('3').attemptMemorization(true)
            bank.getWord('3').attemptMemorization(true)
            bank.getWord('3').attemptMemorization(true)
            probabilities = learning.getWordProbabilities(bank.getAllTranslatedWords())
            expect(probabilities['1']).toBeGreaterThan(probabilities['2'] + 0.001)
            expect(probabilities['2']).toBeGreaterThan(probabilities['3'] + 0.001)

        it 'favours words that have the least number of attempts', () ->
            bank.getWord('1').attemptMemorization(false)
            probabilities = learning.getWordProbabilities(bank.getAllTranslatedWords())
            expect(probabilities['1']).toBeLessThan(probabilities['2'] - 0.001)
            expect(Math.abs(probabilities['2'] - probabilities['3'])).toBeLessThan(0.001)
