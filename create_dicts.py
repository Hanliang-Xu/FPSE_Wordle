#!/usr/bin/env python3
"""Create dictionaries for multi-length Wordle (2-10 letters)"""

from collections import defaultdict
from pathlib import Path

# Seed words by length (common, family-friendly, no proper nouns)
seed_words = {
    2: """
an as at be by do go he if in is it me my no of on or so to up us we
""".split(),

    3: """
add age air and any art ask bag bar bat bed big box boy bus car cat
cow cup cut day dog dry ear eat egg end far fat few fix fly for fox fun
hat hen hit hot ice ink jam job joy key kid leg let low man map may men mom
new not now old one out pen pet pie pig pin pot put red run sad see set sit
sky sun ten the toy try two use war was way wet who why win yes you
""".split(),

    4: """
able also area baby back ball band bank base bear beat been bell best bill bird
blue boat body book both bowl call calm came camp card care case cash cast city
coat cold come cook cool core cost coup crop dark data date dead deal dear deep
desk dial door down draw drop each earn easy east edge even ever face fact fair
fall farm fast feed feel feet file fill film find fine fire firm fish five flat
flow food foot form four free from full game gate gave gift girl give goal gold
good gray half hand hard head hear heat help here hero high hill hold hole home
hope hour huge idea join jump keep kind king knee know lady lake land last late
lead leaf left less life lift like line link list live load long look lose loss
lost love made mail main make many mark meal mean meat meet mild mile milk mind
miss mode more move must name near neck need news next nice nine none nose note
once only open pack page pain pair park part past path pick pile pipe plan play
plot plug plus pool poor port post pour pull pure push race rain rank rare rate
read real rear rent rest rice rich ride ring rise risk road rock role roll roof
room root rule safe sale salt same sand save seat seed seek seem seen self sell
send ship shop show shut side sign site size skin slip slow snow soft soil sold
some song soon sort soup spot star stay step stop such suit sure take tale talk
tall tank tape task team tech tell tend term test text than that them then they
thin this thus tide time tiny told toll tone tool tour town tree trip true turn
type unit upon used user vary vast very view vote wait walk wall want warm wave
weak wear week well went west what when wide wife wild will wind wine wing wire
wise wish with wood word work yard year your zero zone
""".split(),

    5: """
about above actor acute adopt again agent agree ahead align alone along aloud alter
amber ample angel angle angry apple apply arena argue arise armed arrow aside asset
audio audit avoid awake aware bacon badges baker basic basis beach beard beast begin
being belly bench birth black blade blame blank blaze bleed bless blind block blonde
blood bloom board boast bonus boost bored bound brain brand brave bread break brick
bride brief bring broad broke broom brown brush build built buyer cable camel canal
candy carry carve catch cause chain chair chalk charm chart chase cheap chest chief
child chilly china choke churn cider civic class clean clear clerk climb clock
clone close cloth cloud coach coast color coral couch could count court cover crack
craft crane crash cream creek crest crime crisp crowd crown cubic curry cycle daily
dairy dance delay dense depth digit dizzy dozen draft drain drama drawl
dream dress drift drink drive droop eager early earth easel eaten edge eight elder
elect elite email embed empty enact enemy enjoy enter entry equal equip error event
every exact exist extra fancy fatal favor feast fence ferry fiber field fiery
fifth fifty fight final first flame flank flash fleet flesh floor flour
flute focus force forge fraud fresh fried frost fruit fuzzy gauge ghost giant given
glove grace grade grain grand grape graph grass great green greet grind groom group
guava guard guest guide habit happy harsh heart heavy hinge hobby honey honor
horse hotel house human humor hurry ideal image imbed index input inter ionic ivory
jelly jewel joint jolly judge juice juicy kneel knife knock known label labor lacey
large later laugh layer learn leave legal lemon level light limit linen liver local
logic login loose lower lucky magic maker maple march marry match metal meter micro
might minor minus mixed model money month moody moral motor mount mouse mouth movie
music naked natal naval nerve never night noble north nosey novel nurse oaken ocean
offer often older olive onion onset other outer owner oxide paint panel pants party
pasta patch paste peach pearl pedal penny phase phone photo piano piece pilot
plain plane plant plate plead point polar porch power press price pride prime print
prior prize proud prove queen quick quiet quite radio raise range rapid ratio reach
react ready realm reply reset ridge right rigid river roast robot
rocky roman rough round route royal rural sadly safer saint salad scale scarf scene
scoop score scout scrub seize sense serve seven shade shaft shake shall shame shape
share shark sharp shear sheep sheet shelf shine shiny shirt shock shoot shore short
shown shyly sight silky silly since singe sixth sixty skate skill skirt skull
sleep slice slide slope small smart smell smile smoke snack snake snowy solid solve
sound south space spare speak speed spell spend spicy spine sport spray squad stack
stage stain stake stale stall stamp stand starry start state steam steel steep stern
stick stiff still stock stone stood stool store storm story stove strap straw strip
stuck study stuff style sugar suite sunny super sweet swift swing syrup table taken
tasty teach teeth tenth terms thank their theme there thick thief thigh thing think
third thirst three threw thumb tiger tight timer tired title toast today token
topic total touch tough tower trace track trade trail train trait trash treat
trick truce truck trunk trust truth twice twist unity until upper urban usual valid
value vapor vault venue verse video visit vital vivid voice vowel wagon waist
water wheel where which while white whole wider widow width witch woman women
world worry worse worst worth would woven wrist write wrong young youth zebra
zesty
""".split(),

    6: """
abroad accept access across advice affect afford agenda almost always amount animal annual
answer anyone appear around arrive assist assume attack author aware beauty
become before behind belief belong better bitter border bottom branch breath bridge bright
broken broker budget butter button camera cancel cancer cannot carbon career castle
center chance change charge choice choose circle client closed coffee column combat coming
common copper cotton couple course create credit crisis custom damage danger dealer decide
defend define demand depend design desire detail device differ direct doctor dollar double
dragon drawer driver during easily editor effect effort either eleven enable
encour engine enough ensure escape estate ethnic expand expect expert
export extend fabric factor fairly family famous father female figure finger finish flight
flower follow forest formal former foster future garden gather gentle global golden gospel
govern ground growth handle happen hardly health heart heavy hidden hollow human ignore
impact import income indeed infant inside island issue junior kernel
likely limited liquid listen little living loaded local lonely loose lower lucky magic
manual margin market master matter medium memory mental middle minor minute mobile modern
modest moment mother motion motor mount moving nature nearby nearly nobody
normal notice number object office online option orange origin output oxygen
parent partly people period person phrase planet please pocket police
policy proper public purple random really reason recent record reduce region regret
relate remain remind remove render repair repeat report rescue result retail return review
reward rhythm safety salary sample school screen search season second secret senior series
server settle severe shadow should shoulder signal silver simple single sister slight smooth
social soldier solve source speech spirit spring square stable status steady steel
street strike strong summer supply system talent target taught thanks theory thermal
thirty though threat ticket toward travel treaty trouble truly
tunnel twelve twenty unless update useful valley vector vendor vessel victim visual
volume wealth weapon weather weekly weight window winter within wonder worker writer
yellow zeroes
""".split(),

    7: """
ability absence academy account acquire advance against already another arrange article audience average
balance because between blanket bottle boundary capture certain chapter charity
clarity climate clothes collect combine comfort command comment company complex compute connect
consider contact contain content control convert correct costume counsel counter country cousin
courage created crystal culture current curtain default defend deliver density dentist deposit
develop digital diploma direct display distant divide doctor doorway drought economy educate
effect effort elderly element elite embrace emotion employ enable enhance enjoy enquire
ensure equalize escape essence ethic evening exactly example exceed exclude expand expect
explain express extend extreme factory failure family fashion feature federal finally finance
fitness flower foreign formula forward freedom freshen friendly frontier gallery general genetic
genuine geology gesture glasses govern gravity greater healthy helpful history holiday housing
however humanity illegal imagine improve include indoor industry initial insight install instead
intense intend interest involve journey justice keyword kitchen landing laptop latest leather
library limited listen logical loyalty manager marble medical message mineral minimal mobile
moment monitor morning mother muscle museum natural nearby network nothing nuclear numeric
observe officer opinion orange outside package painter partial partner patient payment penalty
people percent perfect perform perhaps physics picture plastic pleasure plenty pocket popular
position poverty precise predict prefer premium prepare present prevent primary privacy problem
process produce profit program project promise protect provide puzzle quality quarter quickly
railway reality receive recover regular relate release remain remark replace request require
respect respond restore result reveal revenue routine scholar science scratch screen season
section sector secure senior service several shelter shortly similar sincere society someone
special sponsor stadium startup station storage stretch student suggest survive teacher theater
therapy thought through thunder tighten traffic transit travel trustee typical uniform unknown
unusual upgrade useful utility variety venture vitamin wedding welcome western whereas whether
""".split(),

    8: """
accuracy activity adoption airplane algebra allergy analysis anything anytime apartment apparent approach
approval argument assembly athletic attitude audience backpack basement behavior birthday boundary building
business calendar campaign capacity category chairman champion chemical childhood circular classroom
clothing coherent commerce commuter complaint complete compound computer consensus consumer continue
contract cooking corridor costume creation criminal critical crossing customer database decision
delivery democracy diameter director disabled discovery distance drawback economist education effective
electricity elevator embassy emergency employer engineer entirely establish estimate evidence
exchange exercise expedition explicit external facility familiar favorite featured festival fireplace
forecast forestry framework friendly frontier generate generator geometry goodwill graduate grateful
handmade hardware headline herbivore highlight homeland honestly hospital identity illustrate immigrant
important incentive incident included increase industry infinite informal informative ingredient
inherent innocence insomnia inspector instinct integral interest interfere internal internet
interview introduce invention investor invited involved irregular jealousy judicious keyboard
landmark language lifespan lighting literal location magazine maintain majority material
maximize meadowland mechanic medicine memorial minister minimize mobility moderate molecule monetary
moreover mountain multiple national negative newborn newcomer nineteen notebook objective observer
occasion official offshore organizer original outsider outreach override pacemaker painting parallel
particle password pastime patience paycheck pediatric penalty perimeter petroleum pipeline
platform pointer portable portrait position possible practice preface pregnant premium prepare
presence pressure previous priority probable problem producer profile progress project properly
proposal prospect protect protocol provided province publicly purchase question quickly quietly
railroad reaction realize receiver recovery regional relative relevant religion remember reminder
renovate research resource response restrict retailer revision rotation sandwich scenario schedule
scientist sculpture security semester sentence separate sequence shoulder simplify software
solution somebody sometimes speechless standard starting statement sterilize stomach straight
strategy strongly structure student submerge suddenly suitcase supplier surgical survival
swimming syllabus talented taxation teenager telegram telephone telescope territory thickness
thousand tolerant tomorrow tradition transfer transit translate triangle tropical ultimate
umbrella underline undertake universal unlikely vacation valuable variable velocity vertical
veterans viewpoint violation visitor volatile volunteer wardrobe whenever wholesale wildlife wireless
workshop yesterday yourself
""".split(),

    9: """
absolutely accordion accidental accountant accurately admission adventure afternoon aggregate algorithm
alphabetic amplifier annoyance apologize architect auditorium automation backbone bacterial
ballooning barometer bartender beautiful benchmark blueberry bookstore brainstorm breakfast briefcase
butterfly cafeteria calculate calendar caretaker carpenter cartilage celebrated cellulose centipede
certainty chocolate cinnamon classical coastline coherence coloring commander commuting companion
competent complaint composer computing consensus container continent controller convenient corridor
counselor courthouse creature crocodile crystalline dangerous dedicated defender deliberate delivering
dentistry depending designing detective developer diaphragm different dimension diplomat directory
disclaimer discovery discussing dishwasher distributor documenter education elevator emergency emotional
empirical employing enclosure encounter encourage endangered endurance enrichment enterprise
entertain envision equitable essential establish evaporation everybody everything evidence
exercised excitement exclusive expansion experience explanation exterior eyewitness fascinated feathering
fertility firefighter firstname footprint forecasting foundation fraternity freshwater friendship
frostbite functional gasoline generator geography geologist guitarist handsome hazardous healthcare
hemisphere hindsight historian historical hospitalized hurricane identical identities immediate
important impossible incentive incorrect indemnity individual industries injection innocent
inspector installer insurance intensive intention interactive intercom interference interject
interprets interview introduction investment investor invisible irrigation journalist landscape
lighthouse literature longevity lowercase mainstream marathon marketing marshmallow mechanic
medication microphone migration millennia miniature ministerial misleading moderator molecular mountain
multiplier narrative naturally necessary newsletter nightmare nobility nonlinear notorious objective
oblivious obsession obtainable occurrence offending offspring operation operational orbits
organized organizer orthopedic otherwise overweight packaging paintwork parameter parliament passenger
passwords pedestrian peninsula percussion petroleum pineapple planetary pollution population portable
portfolio posterior practical predictor preferred pregnancy preliminary premature presidency
president pressure preventive principal printer privileged procedure processor professor
promotion prosperity protective provision quadratic quickness quotation rainforest raspberry
reasonable recipient recycling reference regional registrar rehearsal reinforce rejection relationship
relentless remainder renewable represent residence resistance resources restaurant retelling
retention retrieval revelation revolution ridiculous roughness sanitation satellite scattered
scientific sentiment separator September signature similarity sincerely skeleton slippery snowflake
something sometimes somewhere spectators spherical statement stationery stereotype stimulant strawberry
submarine successful sufficient supervise supervisor supplement surprised surround suspicious
sustainable systematic technical telescope television temporary tentative territories testimony
textbooks thankful thickness threshold trademark translate transverse treatment tribunal
turbulent underline undertaken universal university unrelated vegetation veterinarian victorious
viewpoint violation visibility volleyball warehouse waterfall wholesome wilderness
""".split(),

    10: """
abbreviation abridgement absorbingly acceptable accidental accommodating accomplishment acknowledgement actionable
adolescence aftermarket agriculture alliteration amplification announcement antibiotic anticipated
apparatuses appearance application appraisal apprenticeship architecture brainstorming breadcrumb
breakfasts brightness calculator cancellation capitalism celebration centerpiece
certificate championship cinematography claustrophobia collaboration comfortable combination
commandment commentary competitive complimentary composition compression compulsory considerate
construction consultation contemplation contemporary continuation contributor convenience corporation
correspondence craftsmanship decentralized decomposition demonstration
determination detoxifying differential disinfectant dissatisfaction documentation dramatizing
earthquakes effectiveness electrified electronics encouragement entertainment
environmental establishment extraordinary fluorescence friendliest fundamentally
groundwater harborfront helicopter hospitality housekeeping independence
indeterminate indispensable infrastructure insurmountable international interviewer
jurisdiction kaleidoscope kindergarten knowledgeable laboratories laundromats
lightweight maintenance marketplace microsecond minicomputer misadventure foreseeable
motivation nevertheless notification observatory outstanding
overarching partnership peacefulness personalization photocopier photoreal
playgrounds pocketknife policymaker precipitation preprocessor presentation probability
proclamation productive professional programmer projection proprietary quarterback
questioning quintessential reallocation recalculate recommendation reconstruction
refrigerator relationship representation reproducible responsibilities restaurant
retroactive retrospective revolutionary satisfaction scholarship screwdriver
shareholder significant simultaneous skyscraper smartphone snowmobile spreadsheet
standalone straightforward strengthening subdivisions suboptimal supermarket
surrounding sustainable synchronization technological thermometer
thunderstorm transcription transformation transparency transmogrify
transportation troubleshooting trustworthy unauthorized understandable unpredictable
verification veterinarian virtualization vulnerability waterfall whistleblower
widespread workstation
""".split(),
}

# Clean up questionable or malformed tokens
def clean(words):
    cleaned = []
    for w in words:
        w = w.strip().lower()
        if not w or any(ch for ch in w if not ch.isalpha()):
            continue
        if 2 <= len(w) <= 10:
            cleaned.append(w)
    return cleaned

seed_words = {k: clean(v) for k, v in seed_words.items()}

# Create directory structure and files for each length
base = Path("data")
base.mkdir(parents=True, exist_ok=True)

stats = {
    "words_by_length": {},
    "answers_by_length": {},
}

for length in range(2, 11):
    length_dir = base / f"{length}letter"
    length_dir.mkdir(exist_ok=True)
    
    words = sorted(set(seed_words.get(length, [])))
    
    # Build answers: for short words (2-4), include all; for longer, include subset
    if length <= 4:
        answers = words
    elif length == 5:
        answers = words[:max(1, len(words)*6//10)]
    elif 6 <= length <= 8:
        answers = words[:max(1, len(words)*4//10)]
    else:  # 9-10
        answers = words[:max(1, len(words)*25//100)]
    
    answers = sorted(set(answers))
    
    # Write files
    words_path = length_dir / "words.txt"
    answers_path = length_dir / "answers.txt"
    
    words_path.write_text("\n".join(words) + "\n", encoding="utf-8")
    answers_path.write_text("\n".join(answers) + "\n", encoding="utf-8")
    
    stats["words_by_length"][length] = len(words)
    stats["answers_by_length"][length] = len(answers)
    
    print(f"Created {length}-letter: {len(words)} words, {len(answers)} answers")

print("\n=== Summary ===")
print(f"Total words: {sum(stats['words_by_length'].values())}")
print(f"Total answers: {sum(stats['answers_by_length'].values())}")
print("\nBy length:")
for length in sorted(stats["words_by_length"].keys()):
    print(f"  {length} letters: {stats['words_by_length'][length]} words, {stats['answers_by_length'][length]} answers")

