" Vim syntax file
" Language:     ActionScript
" Maintainer:   Manish Jethani <manish.jethani@gmail.com>
" URL:          http://geocities.com/manish_jethani/actionscript.vim
" Last Change:  2006 June 26
"
"<2008-09-17 三 21:43:20> harry
" Merged some code from syntax/java.vim for highlight asdoc, by harry.

if exists("b:current_syntax")
  finish
endif

syn region  asStringDQ          start=+"+  skip=+\\\\\|\\"+  end=+"+
syn region  asStringSQ          start=+'+  skip=+\\\\\|\\'+  end=+'+
syn match   asNumber          "-\=\<\d\+L\=\>\|0[xX][0-9a-fA-F]\+\>"
syn region  asRegExp          start=+/+ skip=+\\\\\|\\/+ end=+/[gismx]\?\s*$+ end=+/[gismx]\?\s*[;,)]+me=e-1 oneline
" TODO: E4X

syn keyword asCommentTodo     TODO FIXME XXX TBD contained

syn match   asComment         "//.*$" contains=asCommentTodo
syn region  asComment         start="/\*"  end="\*/" contains=asCommentTodo

syn keyword asDirective       import include
syn match   asDirective       "\<use\s\+namespace\>"

syn keyword asAttribute       public private internal protected override final dynamic native static

syn keyword asDefinition      const var class extends interface implements package namespace
syn match   asDefinition        "\<function\(\s\+[gs]et\)\?\>"

syn keyword asGlobal          NaN Infinity undefined eval parseInt parseFloat isNaN isFinite decodeURI decodeURIComponent encodeURI encodeURIComponent

syn keyword asType            Object Function Array String Boolean Number Date Error RegExp XML
syn keyword asType            int uint void *

syn keyword asStatement       if else do while with switch case default continue break return throw try catch finally
syn match   asStatement       "\<for\(\s\+each\)\?\>"

syn keyword asIdentifier      super this

syn keyword asConstant        null true false
syn keyword asOperator        new in is as typeof instanceof delete trace Trace

syn match   asBraces          "[{}]"

syn keyword flash9Functions	Array Boolean decodeURI decodeURIComponent encodeURI encodeURIComponent escape int isFinite isNaN isXMLName Number Object parseFloat parseInt String trace uint unescape XML XMLList
syn keyword flash9Classes	AbstractEvent AbstractInvoker AbstractMessage AbstractOperation AbstractService AbstractTarget Accessibility AccessibilityProperties AccessPrivileges AccessPrivilegesPrivilege Accordion AccordionHeader AccordionHeaderSkin AcknowledgeMessage ActionEffectInstance ActionScriptVersion ActivatorSkin ActivityEvent AddChild AddChildAction AddChildActionInstance Alert AMFChannel AnimateProperty AnimatePropertyInstance AntiAliasType Application ApplicationControlBar ApplicationDomain AreaChart AreaRenderer AreaSeries AreaSeriesItem AreaSeriesRenderData AreaSet ArgumentError arguments Array ArrayCollection ArrayUtil AssociationDefinition AsyncMessage AsyncRequest AsyncToken AVM1Movie AxisBase AxisLabel AxisLabelSet AxisRenderer Back BarChart BarSeries BarSeriesItem BarSeriesRenderData BarSet BaseListData BevelFilter BindingUtils Bitmap BitmapAsset BitmapData BitmapDataChannel BitmapFill BitmapFilter BitmapFilterQuality BitmapFilterType BlendMode Blur BlurFilter BlurInstance Boolean Border Bounce BoundedValue Box BoxDirection BoxItemRenderer BubbleChart BubbleSeries BubbleSeriesItem BubbleSeriesRenderData Button ButtonAsset ButtonBar ButtonBarButtonSkin ButtonLabelPlacement ButtonSkin ByteArray CalendarLayoutChangeEvent Camera CandlestickChart CandlestickItemRenderer CandlestickSeries Canvas Capabilities CapsStyle CartesianChart CartesianTransform CategoryAxis ChangeWatcher Channel ChannelError ChannelEvent ChannelFaultEvent ChannelSet ChartBase ChartElement ChartItem ChartItemEvent ChartLabel ChartState CheckBox CheckBoxIcon ChildExistenceChangedEvent CircleItemRenderer Circular Class ClassFactory ClientInputError CloseEvent CollectionEvent CollectionEventKind CollectionViewError ColorMatrixFilter ColorPicker ColorPickerEvent ColorPickerSkin ColorTransform ColorUtil ColumnChart ColumnSeries ColumnSeriesItem ColumnSeriesRenderData ColumnSet ComboBase ComboBox ComboBoxArrowSkin CommandMessage ComponentDescriptor CompositeEffect CompositeEffectInstance ConcreteDataService Conflict ConflictDetector Conflicts Consumer Container ContainerCreationPolicy ContextMenu ContextMenuBuiltInItems ContextMenuEvent ContextMenuItem ControlBar ConvolutionFilter CreditCardValidator CreditCardValidatorCardType CrossItemRenderer CSMSettings CSSStyleDeclaration Cubic CuePointEvent CuePointManager CurrencyFormatter CurrencyValidator CurrencyValidatorAlignSymbol CursorBookmark CursorError CursorEvent CursorManager CursorManagerPriority DataAssociationMessage DataConflictEvent DataConsumer DataDescription DataErrorMessage DataEvent DataGrid DataGridBase DataGridColumn DataGridColumnDropIndicator DataGridColumnResizeSkin DataGridDragProxy DataGridEvent DataGridEventReason DataGridHeaderSeparator DataGridItemRenderer DataGridListData DataGridSortArrow DataList DataListError DataService DataServiceError DataServiceFaultEvent DataStore DataTip DataTransform Date DateBase DateChooser DateChooserEvent DateChooserEventDetail DateChooserIndicator DateChooserMonthArrowSkin DateChooserYearArrowSkin DateField DateFormatter DateTimeAxis DateValidator DefaultDataDescriptor DeferredInstanceFromClass DeferredInstanceFromFunction DefinitionError DiamondItemRenderer Dictionary DirectHTTPChannel DisplacementMapFilter DisplacementMapFilterMode DisplayObject DisplayObjectContainer Dissolve DissolveInstance DividedBox DividerEvent DownloadProgressBar DragEvent DragManager DragSource DropdownEvent DropShadowFilter DualStyleObject DynamicEvent EdgeMetrics Effect EffectEvent EffectInstance EffectManager EffectTargetFilter Elastic EmailValidator EncodingError Endian EOFError Error ErrorEvent ErrorMessage EvalError Event EventDispatcher EventPhase EventPriority Exponential ExternalInterface Fade FadeInstance Fault FaultEvent FileFilter FileReference FileReferenceList FlexBitmap FlexEvent FlexMovieClip FlexPrintJob FlexPrintJobScaleType FlexShape FlexSimpleButton FlexSprite FlexTextField FocusEvent FocusManager Font FontStyle FontType Form Formatter FormHeading FormItem FormItemDirection FormItemLabel FrameLabel Function Glow GlowFilter GlowInstance GradientBase GradientBevelFilter GradientEntry GradientGlowFilter GradientType Graphics Grid GridFitType GridItem GridLines GridRow HaloBorder HaloColors HaloFocusRect HBox HDividedBox HeaderEvent HistoryManager HitData HLOCChart HLOCItemRenderer HLOCSeries HLOCSeriesBase HLOCSeriesItem HLOCSeriesRenderData HorizontalList HRule HScrollBar HSlider HTTPChannel HTTPRequestMessage HTTPService HTTPService HTTPStatusEvent IAccessPrivileges IAutomationObject IAutomationObjectContainer IAxis IBar IBitmapDrawable IChangeObject IChartElement IChildList ICollectionView IColumn IContainer ID3Info IDataInput IDataOutput IDataRenderer IDeferredInstance IDeferredInstantiationUIComponent IDropInListItemRenderer IDynamicPropertyOutput IDynamicPropertyWriter IEventDispatcher IExternalizable IFactory IFill IFlexAsset IFlexDisplayObject IFocusManager IFocusManagerComponent IFocusManagerContainer IFocusManagerGroup IHistoryManagerClient IIMESupport IInvalidating ILayoutManagerClient IList IListItemRenderer IllegalOperationError ILogger ILoggingTarget Image IManaged IME IMEConversionMode IMEEvent IMenuDataDescriptor IMenuItemRenderer IMessage IMXMLObject IMXMLSupport IndexChangedEvent InstanceCache int InteractiveObject InterpolationMethod InvalidCategoryError InvalidChannelError InvalidDestinationError InvalidFilterError InvalidSWFError IOError IOErrorEvent IOverride IPreloaderDisplay IPropertyChangeNotifier IRawChildrenContainer IRepeater IRepeaterClient IResponder Iris IrisInstance ISimpleStyleClient IStackable IStroke IStyleClient ISystemManager ItemClickEvent ItemPendingError ItemResponder IToolTip IToolTipManagerClient ITreeDataDescriptor IUIComponent IUID IViewCursor JointStyle Keyboard KeyboardEvent KeyLocation Label LayoutManager Legend LegendData LegendItem LegendMouseEvent Linear LinearAxis LinearGradient LinearGradientStroke LineChart LineFormattedTarget LineRenderer LineScaleMode LineSeries LineSeriesItem LineSeriesRenderData LineSeriesSegment LinkBar LinkButton LinkButtonSkin LinkSeparator List ListBase ListBaseSeekPending ListBaseSelectionData ListCollectionView ListData ListDropIndicator ListEvent ListEventReason ListItemDragProxy ListItemRenderer ListItemSelectEvent ListRowInfo Loader LoaderConfig LoaderContext LoaderInfo LoadEvent LocalConnection Locale Log LogAxis LogEvent LogEventLevel LogLogger MaskEffect MaskEffectInstance Math Matrix MBeanAttributeInfo MBeanFeatureInfo MBeanInfo MBeanOperationInfo MBeanParameterInfo MemoryError Menu MenuBar MenuBarBackgroundSkin MenuBarItem MenuEvent MenuItemRenderer MessageAckEvent MessageAgent MessageCacheItem MessageEvent MessageFaultEvent MessagePersister MessagePersisterEvent MessageResponder MessageSerializationError MessageStore MessageStoreEvent MessagingError Metadata MetadataEvent Microphone MiniDebugTarget MorphShape Mouse MouseEvent Move MoveEvent MoveInstance MovieClip MovieClipAsset MovieClipLoaderAsset Namespace NavBar NetConnection NetConnectionChannel NetStatusEvent NetStream NoChannelAvailableError NoDataAvailableError NoSuchChannelError Number NumberBase NumberBaseRoundType NumberFormatter NumberValidator NumericAxis NumericStepper NumericStepperDownSkin NumericStepperEvent NumericStepperUpSkin Object ObjectEncoding ObjectName ObjectProxy ObjectUtil Operation Operation Operation Operation PagedMessage Panel Parallel ParallelInstance Pause PauseInstance PhoneFormatter PhoneNumberValidator PieChart PieSeries PieSeriesItem PieSeriesRenderData PixelSnapping PlotChart PlotSeries PlotSeriesItem PlotSeriesRenderData Point PolarChart PolarTransform PollingChannel PopUpButton PopUpButtonSkin PopUpIcon PopUpManager PopUpManagerChildList PopUpMenuButton PopUpMenuIcon Preloader PrintDataGrid PrintJob PrintJobOptions PrintJobOrientation PriorityQueue Producer ProgrammaticSkin ProgressBar ProgressBarDirection ProgressBarLabelPlacement ProgressBarMode ProgressBarSkin ProgressEvent ProgressIndeterminateSkin ProgressTrackSkin PropertyChangeEvent PropertyChangeEventKind PropertyChanges Proxy QName Quadratic Quartic Quintic RadialGradient RadioButton RadioButtonGroup RadioButtonIcon RangeError Rectangle RectangularBorder RectangularDropShadow ReferenceError RegExp RegExpValidationResult RegExpValidator RemoteObject RemoteObject RemotingMessage RemoveChild RemoveChildAction RemoveChildActionInstance RenderData Repeater Resize ResizeEvent ResizeInstance ResourceBundle Responder ResultEvent RichTextEditor Rotate RotateInstance RoundedRectangle RPCMessage RSLEvent RTMPChannel Scene ScriptTimeoutError ScrollArrowSkin ScrollBar ScrollBarDirection ScrollControlBase ScrollEvent ScrollEventDetail ScrollEventDirection ScrollPolicy ScrollThumb ScrollThumbSkin ScrollTrackSkin SecureAMFChannel Security SecurityDomain SecurityError SecurityErrorEvent SecurityPanel Sequence SequencedMessage SequenceInstance Series SeriesEffect SeriesEffectInstance SeriesInterpolate SeriesInterpolateInstance SeriesSlide SeriesSlideInstance SeriesZoom SeriesZoomInstance SetEventHandler SetProperty SetPropertyAction SetPropertyActionInstance SetStyle SetStyleAction SetStyleActionInstance ShadowBoxItemRenderer ShadowLineRenderer Shape SharedObject SharedObjectFlushStatus SimpleButton SimpleXMLDecoder SimpleXMLEncoder Sine Slider SliderDataTip SliderDirection SliderEvent SliderEventClickTarget SliderHighlightSkin SliderLabel SliderThumb SliderThumbSkin SliderTrackSkin SOAPHeader SOAPMessage SocialSecurityValidator Socket SolidColor Sort SortError SortField Sound SoundAsset SoundChannel SoundEffect SoundEffectInstance SoundLoaderContext SoundMixer SoundTransform Spacer SpreadMethod Sprite SpriteAsset StackedSeries StackOverflowError Stage StageAlign StageQuality StageScaleMode State StateChangeEvent StaticText StatusEvent String StringUtil StringValidator Stroke StyleManager StyleSheet SwatchPanelSkin SwatchSkin SWFLoader SWFVersion SwitchSymbolFormatter SyncEvent SyntaxError System SystemManager TabBar TabNavigator TabSkin Text TextArea TextColorType TextDisplayMode TextEvent TextField TextFieldAsset TextFieldAutoSize TextFieldType TextFormat TextFormatAlign TextInput TextLineMetrics TextRange TextRenderer TextSnapshot Tile TileBase TileBaseDirection TileDirection TileListItemRenderer Timer TimerEvent TitleBackground TitleWindow ToggleButtonBar ToolTip ToolTipBorder ToolTipManager TraceTarget Transform Transition Tree TreeEvent TreeItemRenderer TreeListData TriangleItemRenderer Tween TweenEffect TweenEffectInstance TweenEvent TypeError UIComponent UIComponentCachePolicy UIComponentDescriptor UIDUtil uint UITextField UITextFormat UnresolvedConflictsError UnresolvedConflictsEvent UpdateCollectionMessage UpdateCollectionRange URIError URLLoader URLLoaderDataFormat URLRequest URLRequestHeader URLRequestMethod URLStream URLUtil URLVariables ValidationResult ValidationResultEvent Validator VBox VDividedBox VerifyError Video VideoDisplay VideoError VideoEvent ViewStack VRule VScrollBar VSlider WeakFunctionClosure WeakMethodClosure WebService WebService WedgeItemRenderer WipeDown WipeDownInstance WipeLeft WipeLeftInstance WipeRight WipeRightInstance WipeUp WipeUpInstance WSDLError XML XMLDocument XMLList XMLListCollection XMLNode XMLNodeType XMLUtil ZipCodeFormatter ZipCodeValidatorDomainType Zoom ZoomInstance	

" copyed form java syntax file for highlight asdoc

if version < 508
  command! -nargs=+ JavaHiLink hi link <args>
else
  command! -nargs=+ JavaHiLink hi def link <args>
endif

" Comments
syn keyword javaTodo         contained TODO FIXME XXX
syn region  javaComment         start="/\*"  end="\*/" contains=@javaCommentSpecial,javaTodo,@Spell
syn match   javaCommentStar      contained "^\s*\*[^/]"me=e-1
syn match   javaCommentStar      contained "^\s*\*$"
syn match   javaLineComment      "//.*" contains=@javaCommentSpecial2,javaTodo,@Spell
JavaHiLink javaCommentString javaString
JavaHiLink javaComment2String javaString
JavaHiLink javaCommentCharacter javaCharacter

syn cluster javaTop add=javaComment,javaLineComment

if !exists("as_ignore_asdoc")
  syntax case ignore
  " syntax coloring for javadoc comments (HTML)
  syntax include @javaHtml $VIMRUNTIME/syntax/html.vim
  unlet b:current_syntax
  syn region  javaDocComment    start="/\*\*"  end="\*/" keepend contains=javaCommentTitle,@javaHtml,javaDocTags,javaDocSeeTag,javaTodo,@Spell
  syn region  javaCommentTitle  contained matchgroup=javaDocComment start="/\*\*"   matchgroup=javaCommentTitle keepend end="\.$" end="\.[ \t\r<&]"me=e-1 end="[^{]@"me=s-2,he=s-1 end="\*/"me=s-1,he=s-1 contains=@javaHtml,javaCommentStar,javaTodo,@Spell,javaDocTags,javaDocSeeTag

  syn region javaDocTags         contained start="{@\(link\|linkplain\|inherit[Dd]oc\|doc[rR]oot\|value\)" end="}"
  syn match  javaDocTags         contained "@\(param\|exception\|throws\|since\)\s\+\S\+" contains=javaDocParam
  syn match  javaDocParam        contained "\s\S\+"
  syn match  javaDocTags         contained "@\(version\|author\|return\|deprecated\|serial\|serialField\|serialData\)\>"
  syn region javaDocSeeTag       contained matchgroup=javaDocTags start="@see\s\+" matchgroup=NONE end="\_."re=e-1 contains=javaDocSeeTagParam
  syn match  javaDocSeeTagParam  contained @"\_[^"]\+"\|<a\s\+\_.\{-}</a>\|\(\k\|\.\)*\(#\k\+\((\_[^)]\+)\)\=\)\=@ extend
  syntax case match
endif

" match the special comment /**/
syn match   javaComment         "/\*\*/"

" Flex metadata
syn keyword asMetadataTag     Bindable DefaultProperty Effect Event Exclude IconFile MaxChildren ResourceBundle Style contained
syn match   asMetadata        "^\s*\[.*" contains=asMetadataTag,asStringDQ,asComment

syn sync fromstart
syn sync maxlines=300

hi def link asStringDQ        String
hi def link asStringSQ        String
hi def link asNumber          Number
hi def link asRegExp          Special
hi def link asCommentTodo     Todo
hi def link asComment         Comment
hi def link asDirective       Include
hi def link asAttribute       Define
hi def link asDefinition      Structure
hi def link asGlobal          Macro
hi def link asType            Type
hi def link asStatement       Statement
hi def link asIdentifier      Identifier
hi def link asConstant        Constant
hi def link asOperator        Operator
hi def link asBraces          Function
hi def link flash9Functions   Function
hi def link flash9Classes     Type
hi def link asMetadataTag     PreProc


JavaHiLink javaComment          Comment
JavaHiLink javaDocComment       Comment

JavaHiLink javaCommentTitle     SpecialComment
JavaHiLink javaDocTags          Special
JavaHiLink javaDocParam         Function
JavaHiLink javaDocSeeTagParam   Function
JavaHiLink javaCommentStar      javaComment
JavaHiLink javaLineComment      Comment
JavaHiLink javaTodo             Todo

let b:current_syntax = "actionscript"

" vim: ts=8

