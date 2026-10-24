import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

/// Word Rack: build words from seven letter tiles. Three racks, 60 seconds each.
/// Every rack is built from a real 7-letter word, so a full-rack bonus is always possible.
class WordRackScreen extends StatefulWidget {
  const WordRackScreen({super.key});

  @override
  State<WordRackScreen> createState() => _WordRackScreenState();
}

const List<String> _rackWords = [
  'balance', 'kitchen', 'monster', 'picture', 'station', 'teacher',
  'painter', 'freedom', 'dolphin', 'journey', 'network', 'outline',
  'pattern', 'reading', 'sunrise', 'trainer', 'chapter', 'cabinet',
  'history', 'morning',
];

const String _wordData = '''
act add age ago aid aim air ale all and ant any ape arc are arm art ash ask ate
bad bag ban bar bat bay bed bee bet bid big bin bit bow box boy bud bug bus but buy
cab can cap car cat cop cow cry cub cup cut dad dam day den dew did die dig dim dip
dog dot dry due dug ear eat egg end era eve eye fan far fat fed fee few fig fin fir
fit fix fly fog for fox fry fun fur gap gas gem get got gum gun gut guy had ham has
hat hay hen her hid him hip his hit hop hot how hub hug hut ice ill ink inn ion its
jam jar jaw jet job jog joy key kid kin kit lab lad lag lap law lay led leg let lid
lie lip lit log lot low mad man map mat may men met mix mob mud mug nap net new nil
nod nor not now nut oak oar oat odd off oil old one orb ore our out owl own pad pan
pat paw pay pea pen pet pie pig pin pit pod pot pro pub rag ran rat raw ray red rib
rid rim rip rob rod row rub rug run sad sat saw say sea see set sew she shy sin sip
sir sit ski sky sly son sow spy sub sum sun tab tag tan tap tar tax tea ten the tie
tin tip toe ton too top toy try tub tug urn use van vat vet via vow wag war was wax
way web wed wet who why wig win wit woe won wow yen yes yet you zap zip zoo
able ache acre aged aids aims airs ante ants apes arch area army arts atom aunt away
back bake bald ball band bane bank bare bark barn base bash bass bath bats bead beak
beam bean bear beat been beer bell belt bend bent best bike bill bind bins bird bite
blab blue boat body bold bolt bond bone book boom boot bore born boss both bout bowl
cabs cafe cage cake calm came camp cane cans cape card care cars cart case cash cast
cats cave cent chap char chat chef chew chic chin chip chit cite city clan clap claw
clay clip clue coat code coin cold come cone cook cool cope copy cord core corn cost
cuts cute dare dark darn dart data date dawn days dead deaf deal dean dear deck deed
deem deep deer dent desk dial dice diet dine dint dire dirt dish dive dock does dole
dome done door dose down drag draw drip drop drum dual duck dust each earn ears east
easy eats edge else ends epic even ever exit face fact fade fail fair fall fame fans
fare farm fast fate fear feed feel fees feet fell felt fern file fill film find fine
fire firm fish fist five flag flat flee flew flip flow foam fold folk fond font food
fool foot ford fore fork form fort four free from fuel full fund gain game gape gate
gave gear gift girl give glad glen goal goat goes gold golf gone good grab gram gray
grid grim grin grip grow gulf hair half hall hand hang hard hare harm hate have head
heal hear heat heed heir held hell help hens herb here hero hide high hike hill hind
hint hire hits hold hole holy home hood hook hope horn hose host hour huge hunt hurt
idea inch into iron isle item jail join joke jump june jury just keen keep kept kick
kids kill kind king kiss kite knit knot know lack lady laid lake lamp land lane last
late lazy lead leaf lean leap left lend lens less lick lied life lift like lilt lime
line link lint lion list live load loaf loan lock loft lone long look loop lord lose
loss lost lots loud love luck lung made mail main make male mall many mark mask mass
mate meal mean meat meet melt menu mere mess mind mine mint miss mist mode moms mono
mood moon more most move much must nail name navy near neat neck need nest news next
nice nine node none noon norm nose note noun nuts oath obey once only onto open oral
ours oven over pace pack page paid pain pair pale palm pane pant park part pass past
path pave peak pear peat peel peer pent pert pick pier pile pill pine pink pint pipe
pits plan play plea plod plot plus pole poll pond pony pool poor pope port pose post
pour pray prep pure push quit race rack rage raid rail rain rank rant rare rate read
real rear reed reef rein rely rent rest rice rich ride rind ring riot ripe rise risk
road roar robe rock role roll roof room root rope rose rosy rule runs rush ruin rune
safe sage said sail sake sale salt same sand sane sang save seal seat seed seek seem
seen self sell send sent shed shin ship shop shot show shut sick side sign silk sing
sink site size skin skip slam slap slip slow snap snow soap soar sock soft soil sold
sole some song soon sore sort soul soup spin spot star stay stem step stir stop such
suit sure swan swim tail take tale talk tall tank tape task team tear teen tell tend
tent term tern test text than that them then they thin this thus tick tide tidy tied
tier ties tile till time tine tint tiny tire toad told toll tomb tone took tool tops
tore torn tour town trap tray tree trek trim trio trip true tube tuck tune turn twin
type ugly undo unit upon urge used user vain vary vast very vice view vine visa void
vote wade wage wait wake walk wall want ward warm warn wash wave ways weak wear week
well went were west what when whom wide wife wild will wind wine wing wipe wire wise
wish with woke wolf wood wool word wore work worm worn wrap wren yard yarn year yell
your zero zone
acne actor adore after again alien alone angel anger apart apple arise array aside
bacon badge baker banal basic basin beach beard begin being belie below bench berry
bible birth black blade blame blank blast blaze bleak blend blind block blood bloom
board boast bonus boost brain brake brand brave bread break brick bride brief bring
broad brown brush build built cabin cable canal candy canoe carry catch cause chain
chair chalk charm chart chase cheap cheat check cheek cheer chess chest chief child
chill chin china choir chose cigar civic claim clash class clean clear clerk click
cliff climb clock close cloth cloud coach coast color comic coral couch could count
court cover crack craft crane crash crate crazy cream crept crime crisp cross crowd
crown crude cruel crush curve cycle daily dairy dance dealt death debut decay delay
dense depth diary dirty doubt dough dozen draft drain drama drank drawn dream dress
dried drift drill drink drive drove dwell eager eagle early earth eight elbow elder
elect elite empty enemy enjoy enter equal error essay ethic event every exact exist
extra fable faint fairy faith false fancy fatal fault feast fence fever fiber field
fifth fifty fight final first flame flash fleet flesh float flood floor flour fluid
focus force forge forth forty forum found frame frank fresh front frost fruit fully
funny giant given glass globe glory grace grade grain grand grant grape graph grasp
grass grave great green greet grief grill grind groan groin gross group grown guard
guess guest guide habit happy harsh haste hasty heart heavy hedge hello hence hinge
hobby holly honey honor horse hotel house human humor hurry ideal image index inner
input irony ivory jelly joint judge juice knife knock known label labor laser later
laugh layer leach learn lease least leave legal lemon level light limit linen liver
local logic loose lorry lover lower loyal lucky lunch magic major maker march match
maybe mayor meant medal media melon mercy merit metal meter might minor minus mixed
model money month moral motor mount mouse mouth movie music naive nanny nerve never
newly night noble noise north notch novel nurse occur ocean offer often olive onion
opera orbit order organ other ought outer owner paint panel paper party paste patch
pause peace peach pearl pedal penny phase phone photo piano piece pilot pinch pitch
pizza place plain plane plant plate plaza plead point polar porch pound power prank
press price pride prime print prior prize probe prone proof proud prove pulse punch
pupil queen query quest quick quiet quite quote radio raise rally ranch range rapid
ratio reach react ready realm rebel refer reign relax reply rider ridge right rigid
rinse risen river roast robot rocky rough round route royal rural saint salad sauce
scale scare scene scent scope score scout screw sense serve seven shade shake shall
shame shape share shark sharp shave sheep sheet shelf shell shift shine shiny shirt
shock shoot shore short shown shrug sight silly since sixth sixty skill skirt sleep
slice slide slope small smart smell smile smoke snake solar solid solve sorry sound
south space spare spark speak speed spell spend spent spice spike spine spite split
spoke spoon sport spray squad stack staff stage stain stair stake stale stamp stand
stare start state steak steal steam steel steep stern stick stiff still sting stock
stone stood store storm story stove strap straw strip stuck study stuff style sugar
suite sunny super swarm swear sweat sweep sweet swept swift swing sword table taken
taste teach teeth tempo tenor tense tenth thank theft their theme there these thick
thief thing think third those three threw throw thumb tiger tight timer tired title
toast today token tonic tooth topic torch total touch tough towel tower trace track
trade trail train trait trash treat trend trial tribe trick tried troop truck truly
trunk trust truth tulip twice twist uncle under union unite unity until upper upset
urban usage usual valid value video vigor vinyl virus visit vital vivid vocal voice
voter wagon waist waste watch water weary weave wedge weigh weird whale wheat wheel
where which while white whole whose widen widow width woman world worry worse worst
worth would wound wrist write wrong wrote yacht young youth
abort actor adopt agent alert alter ankle annex ardent attic basic batch behind
bright brother butter cactus candle carpet castle cattle center chance change chapel
charge cheese choice choose circle clever coffee cotton create danger decide degree
desert detail doctor dollar double dragon during effort empire enough escape expert
extend famous farmer father finger finish flight flower forest forget freeze friend
garden gather gentle ginger golden ground growth guitar hammer handle happen harbor
health height helmet hockey honest hunter indeed inside island jacket jungle kitten
ladder laptop launch lawyer leader letter lizard lumber mantle market master matter
member memory mentor middle minute mirror modern moment mother murmur nature needle
noodle normal notice number object online orange origin outfit oxygen packet palace
parent pardon pepper person pickle planet player pocket poetry police potato prince
profit proper public puzzle rabbit random rather reason record reform remain remote
repair report rescue result return reveal rhythm ribbon rocket rubber saddle safety
salmon school screen season second secret select senior series server settle shadow
shield signal silent silver simple single sister smooth social spider spirit spring
square stable steady stream street stress strike string strong studio summer sunset
supply surely swallow symbol system tablet target temple tender thirty thread ticket
tissue tomato tongue travel tunnel turtle unique unless useful valley vector velvet
vessel victim violet visual volume wallet warmth wealth weapon weekly weight window
winter wisdom wonder worker yellow
balance kitchen monster picture station teacher painter freedom dolphin journey
network outline pattern reading sunrise trainer chapter cabinet history morning
repaint pertain retrain terrain nation tinsel stolen violent inspect
''';

final Set<String> _dict = _wordData
    .split(RegExp(r'\s+'))
    .where((w) => w.length >= 3)
    .toSet();

const Map<String, int> _points = {
  'a': 1, 'b': 3, 'c': 3, 'd': 2, 'e': 1, 'f': 4, 'g': 2, 'h': 4, 'i': 1,
  'j': 8, 'k': 5, 'l': 1, 'm': 3, 'n': 1, 'o': 1, 'p': 3, 'q': 10, 'r': 1,
  's': 1, 't': 1, 'u': 1, 'v': 4, 'w': 4, 'x': 8, 'y': 4, 'z': 10,
};

bool _fits(String word, List<String> rack) {
  final pool = [...rack];
  for (final ch in word.split('')) {
    final i = pool.indexOf(ch);
    if (i < 0) return false;
    pool.removeAt(i);
  }
  return true;
}

class _WordRackScreenState extends State<WordRackScreen> {
  static const int _rounds = 3;
  static const int _secondsPerRack = 60;

  final Random _rng = Random();
  Timer? _timer;

  List<String> _rack = [];
  final List<int> _picked = []; // indices into _rack, in order
  final Set<String> _found = {};
  final List<String> _usedRacks = [];
  int _round = 1;
  int _timeLeft = _secondsPerRack;
  int _score = 0;
  int _possible = 0;
  bool _over = false;
  String _msg = 'Tap tiles to spell a word (3+ letters).';
  Color _msgColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _newGame() {
    _usedRacks.clear();
    _round = 1;
    _score = 0;
    _over = false;
    setState(_startRack);
  }

  void _startRack() {
    _timer?.cancel();
    String word;
    do {
      word = _rackWords[_rng.nextInt(_rackWords.length)];
    } while (_usedRacks.contains(word));
    _usedRacks.add(word);
    _rack = word.split('')..shuffle(_rng);
    _picked.clear();
    _found.clear();
    _timeLeft = _secondsPerRack;
    _possible = _dict.where((w) => w.length <= 7 && _fits(w, _rack)).length;
    _msg = 'Tap tiles to spell a word (3+ letters).';
    _msgColor = Colors.white;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) _advance();
      });
    });
  }

  void _advance() {
    if (_round >= _rounds) {
      _timer?.cancel();
      _over = true;
      _picked.clear();
      _timeLeft = 0;
      _msg = 'Game over! Final score: $_score';
      _msgColor = Colors.amber;
    } else {
      _round++;
      _startRack();
    }
  }

  String get _current => _picked.map((i) => _rack[i]).join();

  void _tapRack(int i) {
    if (_over || _picked.contains(i)) return;
    setState(() => _picked.add(i));
  }

  void _tapCurrent(int pos) {
    if (_over) return;
    setState(() => _picked.removeAt(pos));
  }

  int _wordScore(String w) {
    var s = 0;
    for (final ch in w.split('')) {
      s += _points[ch] ?? 0;
    }
    if (w.length >= 5) s *= 2;
    if (w.length == 7) s += 30;
    return s;
  }

  void _submit() {
    if (_over) return;
    final w = _current;
    String? err;
    if (w.length < 3) {
      err = 'Words need at least 3 letters.';
    } else if (_found.contains(w)) {
      err = '"${w.toUpperCase()}" already found.';
    } else if (!_dict.contains(w)) {
      err = '"${w.toUpperCase()}" is not in the word list.';
    }
    setState(() {
      if (err != null) {
        _msg = err;
        _msgColor = Colors.orangeAccent;
      } else {
        final pts = _wordScore(w);
        _score += pts;
        _found.add(w);
        _msg = '${w.toUpperCase()} +$pts${w.length == 7 ? '  FULL RACK!' : ''}';
        _msgColor = Colors.lightGreenAccent;
        _picked.clear();
      }
    });
  }

  void _shuffle() {
    if (_over) return;
    setState(() {
      final letters = _picked.map((i) => _rack[i]).toList();
      _picked.clear();
      _rack.shuffle(_rng);
      // keep the typed word visible by re-picking letters from the new order
      final used = <int>{};
      for (final ch in letters) {
        for (var i = 0; i < _rack.length; i++) {
          if (_rack[i] == ch && !used.contains(i)) {
            used.add(i);
            _picked.add(i);
            break;
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final foundList = _found.toList()..sort((a, b) => b.length - a.length);
    return Scaffold(
      backgroundColor: const Color(0xFF3E2A14),
      appBar: AppBar(
        title: const Text('Word Rack'),
        backgroundColor: const Color(0xFFEF6C00),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'New game',
            icon: const Icon(Icons.refresh),
            onPressed: _newGame,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _stat('Rack', '$_round/$_rounds'),
                  _stat('Time', '${max(0, _timeLeft)}s',
                      warn: _timeLeft <= 10 && !_over),
                  _stat('Score', '$_score'),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: _over ? 0 : _timeLeft / _secondsPerRack,
                minHeight: 6,
                color: _timeLeft <= 10 ? Colors.redAccent : Colors.amber,
                backgroundColor: Colors.black26,
              ),
              const SizedBox(height: 16),
              Text('$_possible words are possible with this rack',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 10),
              // Current word.
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 64),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var p = 0; p < _picked.length; p++)
                      GestureDetector(
                        onTap: () => _tapCurrent(p),
                        child: _tile(_rack[_picked[p]], const Color(0xFFFFE082)),
                      ),
                    if (_picked.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(14),
                        child: Text('Your word',
                            style: TextStyle(color: Colors.white38)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(_msg,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _msgColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              // Rack.
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _rack.length; i++)
                    GestureDetector(
                      onTap: () => _tapRack(i),
                      child: Opacity(
                        opacity: _picked.contains(i) ? 0.25 : 1,
                        child: _tile(_rack[i], const Color(0xFFFFCC80)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _over ? null : _submit,
                    icon: const Icon(Icons.check),
                    label: const Text('Submit'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _over ? null : _shuffle,
                    icon: const Icon(Icons.shuffle),
                    label: const Text('Shuffle'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white),
                  ),
                  OutlinedButton.icon(
                    onPressed: _over ? null : () => setState(_picked.clear),
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white),
                  ),
                  OutlinedButton.icon(
                    onPressed: _over
                        ? null
                        : () => setState(() {
                              _advance();
                            }),
                    icon: const Icon(Icons.skip_next),
                    label: Text(_round >= _rounds ? 'Finish' : 'Next rack'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white),
                  ),
                  if (_over)
                    ElevatedButton.icon(
                      onPressed: _newGame,
                      icon: const Icon(Icons.replay),
                      label: const Text('Play again'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Found (${foundList.length})',
                    style: const TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final w in foundList)
                      Chip(
                        label: Text('${w.toUpperCase()}  ${_wordScore(w)}'),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Letter values: common letters 1, rarer letters up to 10. '
                '5+ letter words score double; a 7-letter word adds +30.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value, {bool warn = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Text(
          value,
          style: TextStyle(
            color: warn ? Colors.redAccent : Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _tile(String letter, Color color) {
    return Container(
      width: 44,
      height: 48,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF8D6E63), width: 2),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              letter.toUpperCase(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF3E2723),
              ),
            ),
          ),
          Positioned(
            right: 3,
            bottom: 1,
            child: Text(
              '${_points[letter] ?? 0}',
              style: const TextStyle(fontSize: 9, color: Color(0xFF3E2723)),
            ),
          ),
        ],
      ),
    );
  }
}
