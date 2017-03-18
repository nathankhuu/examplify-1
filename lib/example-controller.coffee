{ ExampleModelState, ExampleModelProperty } = require "./model/example-model"
{ MissingDefinitionDetector } = require "./error/missing-definition"
{ MissingDeclarationDetector } = require "./error/missing-declaration"
{ DefinitionSuggester } = require "./suggester/definition-suggester"
{ DeclarationSuggester } = require "./suggester/declaration-suggester"
{ PrimitiveValueSuggester } = require "./suggester/primitive-value-suggester"
{ InstanceStubSuggester } = require "./suggester/instance-stub-suggester"
{ RangeAddition } = require "./edit/range-addition"
{ Fixer } = require "./fixer"

module.exports.ExampleController = class ExampleController

  constructor: (model, analyses, correctors) ->

    # Listen to all changes in the model
    @model = model
    @model.addObserver @

    defUseAnalysis = analyses.defUseAnalysis
    valueAnalysis = analyses.valueAnalysis
    stubAnalysis = analyses.stubAnalysis

    @correctors = correctors
    # Load default correctors if none were passed in
    if not @correctors?
      @correctors = [
          checker: new MissingDefinitionDetector()
          suggesters: [
            new DefinitionSuggester()
            new PrimitiveValueSuggester()
            new InstanceStubSuggester()
          ]
        ,
          checker: new MissingDeclarationDetector()
          suggesters: [ new DeclarationSuggester() ]
      ]

    # Before the state can update, the analyses must complete
    @_startAnalyses defUseAnalysis, valueAnalysis, stubAnalysis

  _startAnalyses: (defUseAnalysis, valueAnalysis, stubAnalysis) ->

    # Save a reference to analyses
    @analyses =
      defUse:
        runner: defUseAnalysis
        callback: (analysis) =>
          @model.getSymbols().setDefs analysis.getDefs()
          @model.getSymbols().setUses analysis.getUses()
        error: console.error
      value:
        runner: valueAnalysis or= null
        callback: (valueMap) =>
          @model.setValueMap valueMap
        error: console.error
      stub:
        runner: stubAnalysis or= null
        callback: (stubSpecTable) =>
          console.log "Callback:", stubSpecTable
          @model.setStubSpecTable stubSpecTable
        error: console.error

    # Run analyses sequentially.  Soot can't handle when more than one
    # analysis is running at a time.  Pattern reference for chaining promises:
    # http://stackoverflow.com/questions/24586110/resolve-promises-one-after-another-i-e-in-sequence
    analysisDone = Promise.resolve()
    for _, analysis of @analyses
      analysisDone = analysisDone.then (() ->
        new Promise (resolve, reject) =>
          resolve() if not @runner?
          @runner.run ((outcome) =>
            @callback outcome
            resolve()
          ), () =>
            # Even on error, claim that we have "resolved" the promise,
            # just so we can keep moving onto the next analysis.
            @error()
            resolve()
        ).bind analysis
    analysisDone.then =>
      @model.setState ExampleModelState.IDLE

  applyCorrectors: ->
    for corrector in @correctors
      errors = corrector.checker.detectErrors @model
      if errors.length > 0
        # It's important that the state gets set last, as it's the
        # state change that the view will be refreshing on
        @model.setErrors errors
        @model.setActiveCorrector corrector
        @model.setState ExampleModelState.ERROR_CHOICE
        break

  getSuggestions: ->
    error = @model.getErrorChoice()
    activeCorrector = @model.getActiveCorrector()
    suggestions = []
    for suggester in activeCorrector.suggesters
      suggesterSuggestions = suggester.getSuggestions error, @model
      suggestions = suggestions.concat suggesterSuggestions
    suggestions

  onPropertyChanged: (object, propertyName, propertyValue) ->

    if @model.getState() is ExampleModelState.IDLE

      if propertyName is ExampleModelProperty.STATE
        @applyCorrectors()
      else if propertyName is ExampleModelProperty.ACTIVE_RANGES
        @applyCorrectors()

    else if @model.getState() is ExampleModelState.ERROR_CHOICE

      if (propertyName is ExampleModelProperty.ERROR_CHOICE) and propertyValue?
        suggestions = @getSuggestions()
        @model.setSuggestions suggestions
        @model.setState ExampleModelState.RESOLUTION

    else if @model.getState() is ExampleModelState.RESOLUTION

      if (propertyName is ExampleModelProperty.RESOLUTION_CHOICE) and propertyValue?

        if propertyValue instanceof RangeAddition
          @model.getRangeSet().getActiveRanges().push propertyValue.getRange()
        else
          fixer = new Fixer()
          fixer.apply @model, propertyValue

        @model.setActiveCorrector null
        @model.setState ExampleModelState.IDLE
