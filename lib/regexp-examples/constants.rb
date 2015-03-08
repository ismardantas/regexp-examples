module RegexpExamples
  class ResultCountLimiters
    # The maximum variance for any given repeater, to prevent a huge/infinite number of
    # examples from being listed. For example, if @@max_repeater_variance = 2 then:
    # .* is equivalent to .{0,2}
    # .+ is equivalent to .{1,3}
    # .{2,} is equivalent to .{2,4}
    # .{,3} is equivalent to .{0,2}
    # .{3,8} is equivalent to .{3,5}
    MaxRepeaterVarianceDefault = 2

    # Maximum number of characters returned from a char set, to reduce output spam
    # For example, if @@max_group_results = 5 then:
    # \d = ["0", "1", "2", "3", "4"]
    # \w = ["a", "b", "c", "d", "e"]
    MaxGroupResultsDefault = 5

    class << self
      attr_reader :max_repeater_variance, :max_group_results
      def configure!(max_repeater_variance, max_group_results = nil)
        @max_repeater_variance = (max_repeater_variance || MaxRepeaterVarianceDefault)
        @max_group_results = (max_group_results || MaxGroupResultsDefault)
      end
    end
  end

  def self.MaxRepeaterVariance
    ResultCountLimiters.max_repeater_variance
  end
  def self.MaxGroupResults
    ResultCountLimiters.max_group_results
  end

  module CharSets
    Lower        = Array('a'..'z')
    Upper        = Array('A'..'Z')
    Digit        = Array('0'..'9')
    # Note: Punct should also include the following chars: $ + < = > ^ ` | ~
    # I.e. Punct = %w(! " # $ % & ' ( ) * + , - . / : ; < = > ? @ [ \\ ] ^ _ ` { | } ~)
    # However, due to a ruby bug (!!) these do not work properly at the moment!
    Punct        = %w(! " # % & ' ( ) * , - . / : ; ? @ [ \\ ] _ { })
    Hex          = Array('a'..'f') | Array('A'..'F') | Digit
    Word         = Lower | Upper | Digit | ['_']
    Whitespace   = [' ', "\t", "\n", "\r", "\v", "\f"]
    Control      = (0..31).map(&:chr) | ["\x7f"]
    # Ensure that the "common" characters appear first in the array
    # Also, ensure "\n" comes first, to make it obvious when included
    Any          = ["\n"] | Lower | Upper | Digit | Punct | (0..127).map(&:chr)
    AnyNoNewLine = Any - ["\n"]
  end.freeze

  # Map of special regex characters, to their associated character sets
  BackslashCharMap = {
    'd' => CharSets::Digit,
    'D' => CharSets::Any - CharSets::Digit,
    'w' => CharSets::Word,
    'W' => CharSets::Any - CharSets::Word,
    's' => CharSets::Whitespace,
    'S' => CharSets::Any - CharSets::Whitespace,
    'h' => CharSets::Hex,
    'H' => CharSets::Any - CharSets::Hex,

    't' => ["\t"], # tab
    'n' => ["\n"], # new line
    'r' => ["\r"], # carriage return
    'f' => ["\f"], # form feed
    'a' => ["\a"], # alarm
    'v' => ["\v"], # vertical tab
    'e' => ["\e"], # escape
  }.freeze

  POSIXCharMap = {
    'alnum'  => CharSets::Upper | CharSets::Lower | CharSets::Digit,
    'alpha'  => CharSets::Upper | CharSets::Lower,
    'blank'  => [" ", "\t"],
    'cntrl'  => CharSets::Control,
    'digit'  => CharSets::Digit,
    'graph'  => (CharSets::Any - CharSets::Control) - [" "], #  Visible chars
    'lower'  => CharSets::Lower,
    'print'  => CharSets::Any - CharSets::Control,
    'punct'  => CharSets::Punct,
    'space'  => CharSets::Whitespace,
    'upper'  => CharSets::Upper,
    'xdigit' => CharSets::Hex,
    'word'   => CharSets::Word,
    'ascii'  => CharSets::Any
  }.freeze

  def self.ranges_to_unicode(*ranges)
    result = []
    ranges.each do |range|
      if range.is_a? Fixnum # Small hack to improve readability below
        result << hex_to_unicode(range.to_s(16))
      else
        range.each { |num| result << hex_to_unicode(num.to_s(16)) }
      end
    end
    result
  end

  def self.hex_to_unicode(hex)
    eval("?\\u{#{hex}}")
  end

  # These values were generated by: scripts/unicode_lister.rb
  # Note: Only the first 128 results are listed, for performance.
  # Also, some groups seem to have no matches (weird!)
  NamedPropertyCharMap = {
    'alnum' => ranges_to_unicode(48..57, 65..90, 97..122, 170, 181, 186, 192..214, 216..246, 248..256),
    'alpha' => ranges_to_unicode(65..90, 97..122, 170, 181, 186, 192..214, 216..246, 248..266),
    'blank' => ranges_to_unicode(9, 32, 160, 5760, 8192..8202, 8239, 8287, 12288),
    'cntrl' => ranges_to_unicode(0..31, 127..159),
    'digit' => ranges_to_unicode(48..57, 1632..1641, 1776..1785, 1984..1993, 2406..2415, 2534..2543, 2662..2671, 2790..2799, 2918..2927, 3046..3055, 3174..3183, 3302..3311, 3430..3437),
    'graph' => ranges_to_unicode(33..126, 161..194),
    'lower' => ranges_to_unicode(97..122, 170, 181, 186, 223..246, 248..255, 257, 259, 261, 263, 265, 267, 269, 271, 273, 275, 277, 279, 281, 283, 285, 287, 289, 291, 293, 295, 297, 299, 301, 303, 305, 307, 309, 311..312, 314, 316, 318, 320, 322, 324, 326, 328..329, 331, 333, 335, 337, 339, 341, 343, 345, 347, 349, 351, 353, 355, 357, 359, 361, 363, 365, 367, 369, 371, 373, 375, 378, 380, 382..384, 387),
    'print' => ranges_to_unicode(32..126, 160..192),
    'punct' => ranges_to_unicode(33..35, 37..42, 44..47, 58..59, 63..64, 91..93, 95, 123, 125, 161, 167, 171, 182..183, 187, 191, 894, 903, 1370..1375, 1417..1418, 1470, 1472, 1475, 1478, 1523..1524, 1545..1546, 1548..1549, 1563, 1566..1567, 1642..1645, 1748, 1792..1805, 2039..2041, 2096..2110, 2142, 2404..2405, 2416, 2800, 3572, 3663, 3674..3675, 3844..3858, 3860, 3898..3901, 3973, 4048..4052, 4057..4058, 4170),
    'space' => ranges_to_unicode(9..13, 32, 133, 160, 5760, 8192..8202, 8232..8233, 8239, 8287, 12288),
    'upper' => ranges_to_unicode(65..90, 192..214, 216..222, 256, 258, 260, 262, 264, 266, 268, 270, 272, 274, 276, 278, 280, 282, 284, 286, 288, 290, 292, 294, 296, 298, 300, 302, 304, 306, 308, 310, 313, 315, 317, 319, 321, 323, 325, 327, 330, 332, 334, 336, 338, 340, 342, 344, 346, 348, 350, 352, 354, 356, 358, 360, 362, 364, 366, 368, 370, 372, 374, 376..377, 379, 381, 385..386, 388, 390..391, 393..395, 398),
    'xdigit' => ranges_to_unicode(48..57, 65..70, 97..102),
    'word' => ranges_to_unicode(48..57, 65..90, 95, 97..122, 170, 181, 186, 192..214, 216..246, 248..255),
    'ascii' => ranges_to_unicode(0..127),
    'any' => ranges_to_unicode(0..127),
    'assigned' => ranges_to_unicode(0..127),
    'l' => ranges_to_unicode(65..90, 97..122, 170, 181, 186, 192..214, 216..246, 248..266),
    'll' => ranges_to_unicode(97..122, 181, 223..246, 248..255, 257, 259, 261, 263, 265, 267, 269, 271, 273, 275, 277, 279, 281, 283, 285, 287, 289, 291, 293, 295, 297, 299, 301, 303, 305, 307, 309, 311..312, 314, 316, 318, 320, 322, 324, 326, 328..329, 331, 333, 335, 337, 339, 341, 343, 345, 347, 349, 351, 353, 355, 357, 359, 361, 363, 365, 367, 369, 371, 373, 375, 378, 380, 382..384, 387, 389, 392),
    'lm' => ranges_to_unicode(688..705, 710..721, 736..740, 748, 750, 884, 890, 1369, 1600, 1765..1766, 2036..2037, 2042, 2074, 2084, 2088, 2417, 3654, 3782, 4348, 6103, 6211, 6823, 7288..7293, 7468..7530, 7544, 7579..7580),
    'lo' => ranges_to_unicode(170, 186, 443, 448..451, 660, 1488..1514, 1520..1522, 1568..1599, 1601..1610, 1646..1647, 1649..1694),
    'lt' => ranges_to_unicode(453, 456, 459, 498, 8072..8079, 8088..8095, 8104..8111, 8124, 8140, 8188),
    'lu' => ranges_to_unicode(65..90, 192..214, 216..222, 256, 258, 260, 262, 264, 266, 268, 270, 272, 274, 276, 278, 280, 282, 284, 286, 288, 290, 292, 294, 296, 298, 300, 302, 304, 306, 308, 310, 313, 315, 317, 319, 321, 323, 325, 327, 330, 332, 334, 336, 338, 340, 342, 344, 346, 348, 350, 352, 354, 356, 358, 360, 362, 364, 366, 368, 370, 372, 374, 376..377, 379, 381, 385..386, 388, 390..391, 393..395, 398),
    'm' => ranges_to_unicode(768..879, 1155..1161, 1425..1433),
    'mn' => ranges_to_unicode(768..879, 1155..1159, 1425..1435),
    'mc' => ranges_to_unicode(2307, 2363, 2366..2368, 2377..2380, 2382..2383, 2434..2435, 2494..2496, 2503..2504, 2507..2508, 2519, 2563, 2622..2624, 2691, 2750..2752, 2761, 2763..2764, 2818..2819, 2878, 2880, 2887..2888, 2891..2892, 2903, 3006..3007, 3009..3010, 3014..3016, 3018..3020, 3031, 3073..3075, 3137..3140, 3202..3203, 3262, 3264..3268, 3271..3272, 3274..3275, 3285..3286, 3330..3331, 3390..3392, 3398..3400, 3402..3404, 3415, 3458..3459, 3535..3537, 3544..3551, 3570..3571, 3902..3903, 3967, 4139..4140, 4145, 4152, 4155..4156, 4182..4183, 4194..4196, 4199..4205, 4227..4228, 4231..4235),
    'me' => ranges_to_unicode(1160..1161, 6846, 8413..8416, 8418..8420, 42608..42610),
    'n' => ranges_to_unicode(48..57, 178..179, 185, 188..190, 1632..1641, 1776..1785, 1984..1993, 2406..2415, 2534..2543, 2548..2553, 2662..2671, 2790..2799, 2918..2927, 2930..2935, 3046..3058, 3174..3180),
    'nd' => ranges_to_unicode(48..57, 1632..1641, 1776..1785, 1984..1993, 2406..2415, 2534..2543, 2662..2671, 2790..2799, 2918..2927, 3046..3055, 3174..3183, 3302..3311, 3430..3437),
    'nl' => ranges_to_unicode(5870..5872, 8544..8578, 8581..8584, 12295, 12321..12329, 12344..12346, 42726..42735),
    'no' => ranges_to_unicode(178..179, 185, 188..190, 2548..2553, 2930..2935, 3056..3058, 3192..3198, 3440..3445, 3882..3891, 4969..4988, 6128..6137, 6618, 8304, 8308..8313, 8320..8329, 8528..8543, 8585, 9312..9330),
    'p' => ranges_to_unicode(33..35, 37..42, 44..47, 58..59, 63..64, 91..93, 95, 123, 125, 161, 167, 171, 182..183, 187, 191, 894, 903, 1370..1375, 1417..1418, 1470, 1472, 1475, 1478, 1523..1524, 1545..1546, 1548..1549, 1563, 1566..1567, 1642..1645, 1748, 1792..1805, 2039..2041, 2096..2110, 2142, 2404..2405, 2416, 2800, 3572, 3663, 3674..3675, 3844..3858, 3860, 3898..3901, 3973, 4048..4052, 4057..4058, 4170),
    'pc' => ranges_to_unicode(95, 8255..8256, 8276),
    'pd' => ranges_to_unicode(45, 1418, 1470, 5120, 6150, 8208..8213, 11799, 11802, 11834..11835, 11840, 12316, 12336, 12448),
    'ps' => ranges_to_unicode(40, 91, 123, 3898, 3900, 5787, 8218, 8222, 8261, 8317, 8333, 8968, 8970, 9001, 10088, 10090, 10092, 10094, 10096, 10098, 10100, 10181, 10214, 10216, 10218, 10220, 10222, 10627, 10629, 10631, 10633, 10635, 10637, 10639, 10641, 10643, 10645, 10647, 10712, 10714, 10748, 11810, 11812, 11814, 11816, 11842, 12296, 12298, 12300, 12302, 12304, 12308, 12310, 12312, 12314, 12317),
    'pe' => ranges_to_unicode(41, 93, 125, 3899, 3901, 5788, 8262, 8318, 8334, 8969, 8971, 9002, 10089, 10091, 10093, 10095, 10097, 10099, 10101, 10182, 10215, 10217, 10219, 10221, 10223, 10628, 10630, 10632, 10634, 10636, 10638, 10640, 10642, 10644, 10646, 10648, 10713, 10715, 10749, 11811, 11813, 11815, 11817, 12297, 12299, 12301, 12303, 12305, 12309, 12311, 12313, 12315, 12318..12319),
    'pi' => ranges_to_unicode(171, 8216, 8219..8220, 8223, 8249, 11778, 11780, 11785, 11788, 11804, 11808),
    'pf' => ranges_to_unicode(187, 8217, 8221, 8250, 11779, 11781, 11786, 11789, 11805, 11809),
    'po' => ranges_to_unicode(33..35, 37..39, 42, 44, 46..47, 58..59, 63..64, 92, 161, 167, 182..183, 191, 894, 903, 1370..1375, 1417, 1472, 1475, 1478, 1523..1524, 1545..1546, 1548..1549, 1563, 1566..1567, 1642..1645, 1748, 1792..1805, 2039..2041, 2096..2110, 2142, 2404..2405, 2416, 2800, 3572, 3663, 3674..3675, 3844..3858, 3860, 3973, 4048..4052, 4057..4058, 4170..4175, 4347, 4960..4968, 5741),
    's' => ranges_to_unicode(36, 43, 60..62, 94, 96, 124, 126, 162..166, 168..169, 172, 174..177, 180, 184, 215, 247, 706..709, 722..735, 741..747, 749, 751..767, 885, 900..901, 1014, 1154, 1421..1423, 1542..1544, 1547, 1550..1551, 1758, 1769, 1789..1790, 2038, 2546..2547, 2554..2555, 2801, 2928, 3059..3066, 3199, 3449, 3647, 3841..3843, 3859, 3861..3863, 3866..3871, 3892, 3894, 3896, 4030..4037),
    'sm' => ranges_to_unicode(43, 60..62, 124, 126, 172, 177, 215, 247, 1014, 1542..1544, 8260, 8274, 8314..8316, 8330..8332, 8472, 8512..8516, 8523, 8592..8596, 8602..8603, 8608, 8611, 8614, 8622, 8654..8655, 8658, 8660, 8692..8775),
    'sc' => ranges_to_unicode(36, 162..165, 1423, 1547, 2546..2547, 2555, 2801, 3065, 3647, 6107, 8352..8381, 43064),
    'sk' => ranges_to_unicode(94, 96, 168, 175, 180, 184, 706..709, 722..735, 741..747, 749, 751..767, 885, 900..901, 8125, 8127..8129, 8141..8143, 8157..8159, 8173..8175, 8189..8190, 12443..12444, 42752..42774, 42784..42785, 42889..42890, 43867),
    'so' => ranges_to_unicode(166, 169, 174, 176, 1154, 1421..1422, 1550..1551, 1758, 1769, 1789..1790, 2038, 2554, 2928, 3059..3064, 3066, 3199, 3449, 3841..3843, 3859, 3861..3863, 3866..3871, 3892, 3894, 3896, 4030..4037, 4039..4044, 4046..4047, 4053..4056, 4254..4255, 5008..5017, 6464, 6622..6655, 7009..7018, 7028..7036, 8448),
    'z' => ranges_to_unicode(32, 160, 5760, 8192..8202, 8232..8233, 8239, 8287, 12288),
    'zs' => ranges_to_unicode(32, 160, 5760, 8192..8202, 8239, 8287, 12288),
    'zl' => ranges_to_unicode(8232),
    'zp' => ranges_to_unicode(8233),
    'c' => ranges_to_unicode(0..31, 127..159, 173, 888..889, 896..899, 907, 909, 930, 1328, 1367..1368, 1376, 1416, 1419..1420, 1424, 1480..1487, 1515..1519, 1525..1541, 1564..1565, 1757, 1806..1807, 1867..1868, 1970..1977),
    'cc' => ranges_to_unicode(0..31, 127..159),
    'cf' => ranges_to_unicode(173, 1536..1541, 1564, 1757, 1807, 6158, 8203..8207, 8234..8238, 8288..8292, 8294..8303),
    'cn' => ranges_to_unicode(888..889, 896..899, 907, 909, 930, 1328, 1367..1368, 1376, 1416, 1419..1420, 1424, 1480..1487, 1515..1519, 1525..1535, 1565, 1806, 1867..1868, 1970..1983, 2043..2047, 2094..2095, 2111, 2140..2141, 2143..2201),
    'co' => ranges_to_unicode(),
    'cs' => ranges_to_unicode(),
    'arabic' => ranges_to_unicode(1536..1540, 1542..1547, 1549..1562, 1566, 1568..1599, 1601..1610, 1622..1631, 1642..1647, 1649..1692),
    'armenian' => ranges_to_unicode(1329..1366, 1369..1375, 1377..1415, 1418, 1421..1423),
    'balinese' => ranges_to_unicode(6912..6987, 6992..7036),
    'bengali' => ranges_to_unicode(2432..2435, 2437..2444, 2447..2448, 2451..2472, 2474..2480, 2482, 2486..2489, 2492..2500, 2503..2504, 2507..2510, 2519, 2524..2525, 2527..2531, 2534..2555),
    'bopomofo' => ranges_to_unicode(746..747, 12549..12589, 12704..12730),
    'braille' => ranges_to_unicode(10240..10367),
    'buginese' => ranges_to_unicode(6656..6683, 6686..6687),
    'buhid' => ranges_to_unicode(5952..5971),
    'canadian_aboriginal' => ranges_to_unicode(5120..5247),
    'carian' => ranges_to_unicode(),
    'cham' => ranges_to_unicode(43520..43574, 43584..43597, 43600..43609, 43612..43615),
    'cherokee' => ranges_to_unicode(5024..5108),
    'common' => ranges_to_unicode(0..64, 91..96, 123..169, 171..180),
    'coptic' => ranges_to_unicode(994..1007, 11392..11505),
    'cuneiform' => ranges_to_unicode(),
    'cypriot' => ranges_to_unicode(),
    'cyrillic' => ranges_to_unicode(1024..1151),
    'deseret' => ranges_to_unicode(),
    'devanagari' => ranges_to_unicode(2304..2384, 2387..2403, 2406..2431, 43232..43235),
    'ethiopic' => ranges_to_unicode(4608..4680, 4682..4685, 4688..4694, 4696, 4698..4701, 4704..4742),
    'georgian' => ranges_to_unicode(4256..4293, 4295, 4301, 4304..4346, 4348..4351, 11520..11557, 11559, 11565),
    'glagolitic' => ranges_to_unicode(11264..11310, 11312..11358),
    'gothic' => ranges_to_unicode(),
    'greek' => ranges_to_unicode(880..883, 885..887, 890..893, 895, 900, 902, 904..906, 908, 910..929, 931..993, 1008..1023, 7462..7466, 7517..7521, 7526),
    'gujarati' => ranges_to_unicode(2689..2691, 2693..2701, 2703..2705, 2707..2728, 2730..2736, 2738..2739, 2741..2745, 2748..2757, 2759..2761, 2763..2765, 2768, 2784..2787, 2790..2801),
    'gurmukhi' => ranges_to_unicode(2561..2563, 2565..2570, 2575..2576, 2579..2600, 2602..2608, 2610..2611, 2613..2614, 2616..2617, 2620, 2622..2626, 2631..2632, 2635..2637, 2641, 2649..2652, 2654, 2662..2677),
    'han' => ranges_to_unicode(11904..11929, 11931..12019, 12032..12044),
    'hangul' => ranges_to_unicode(4352..4479),
    'hanunoo' => ranges_to_unicode(5920..5940),
    'hebrew' => ranges_to_unicode(1425..1479, 1488..1514, 1520..1524),
    'hiragana' => ranges_to_unicode(12353..12438, 12445..12447),
    'inherited' => ranges_to_unicode(768..879, 1157..1158, 1611..1621, 1648, 2385..2386),
    'kannada' => ranges_to_unicode(3201..3203, 3205..3212, 3214..3216, 3218..3240, 3242..3251, 3253..3257, 3260..3268, 3270..3272, 3274..3277, 3285..3286, 3294, 3296..3299, 3302..3311, 3313..3314),
    'katakana' => ranges_to_unicode(12449..12538, 12541..12543, 12784..12799, 13008..13026),
    'kayah_li' => ranges_to_unicode(43264..43309, 43311),
    'kharoshthi' => ranges_to_unicode(),
    'khmer' => ranges_to_unicode(6016..6109, 6112..6121, 6128..6137, 6624..6637),
    'lao' => ranges_to_unicode(3713..3714, 3716, 3719..3720, 3722, 3725, 3732..3735, 3737..3743, 3745..3747, 3749, 3751, 3754..3755, 3757..3769, 3771..3773, 3776..3780, 3782, 3784..3789, 3792..3801, 3804..3807),
    'latin' => ranges_to_unicode(65..90, 97..122, 170, 186, 192..214, 216..246, 248..267),
    'lepcha' => ranges_to_unicode(7168..7223, 7227..7241, 7245..7247),
    'limbu' => ranges_to_unicode(6400..6430, 6432..6443, 6448..6459, 6464, 6468..6479),
    'linear_b' => ranges_to_unicode(),
    'lycian' => ranges_to_unicode(),
    'lydian' => ranges_to_unicode(),
    'malayalam' => ranges_to_unicode(3329..3331, 3333..3340, 3342..3344, 3346..3386, 3389..3396, 3398..3400, 3402..3406, 3415, 3424..3427, 3430..3445, 3449..3455),
    'mongolian' => ranges_to_unicode(6144..6145, 6148, 6150..6158, 6160..6169, 6176..6263, 6272..6289),
    'myanmar' => ranges_to_unicode(4096..4223),
    'new_tai_lue' => ranges_to_unicode(6528..6571, 6576..6601, 6608..6618, 6622..6623),
    'nko' => ranges_to_unicode(1984..2042),
    'ogham' => ranges_to_unicode(5760..5788),
    'ol_chiki' => ranges_to_unicode(7248..7295),
    'old_italic' => ranges_to_unicode(),
    'old_persian' => ranges_to_unicode(),
    'oriya' => ranges_to_unicode(2817..2819, 2821..2828, 2831..2832, 2835..2856, 2858..2864, 2866..2867, 2869..2873, 2876..2884, 2887..2888, 2891..2893, 2902..2903, 2908..2909, 2911..2915, 2918..2935),
    'osmanya' => ranges_to_unicode(),
    'phags_pa' => ranges_to_unicode(43072..43127),
    'phoenician' => ranges_to_unicode(),
    'rejang' => ranges_to_unicode(43312..43347, 43359),
    'runic' => ranges_to_unicode(5792..5866, 5870..5880),
    'saurashtra' => ranges_to_unicode(43136..43204, 43214..43225),
    'shavian' => ranges_to_unicode(),
    'sinhala' => ranges_to_unicode(3458..3459, 3461..3478, 3482..3505, 3507..3515, 3517, 3520..3526, 3530, 3535..3540, 3542, 3544..3551, 3558..3567, 3570..3572),
    'sundanese' => ranges_to_unicode(7040..7103, 7360..7367),
    'syloti_nagri' => ranges_to_unicode(43008..43051),
    'syriac' => ranges_to_unicode(1792..1805, 1807..1866, 1869..1871),
    'tagalog' => ranges_to_unicode(5888..5900, 5902..5908),
    'tagbanwa' => ranges_to_unicode(5984..5996, 5998..6000, 6002..6003),
    'tai_le' => ranges_to_unicode(6480..6509, 6512..6516),
    'tamil' => ranges_to_unicode(2946..2947, 2949..2954, 2958..2960, 2962..2965, 2969..2970, 2972, 2974..2975, 2979..2980, 2984..2986, 2990..3001, 3006..3010, 3014..3016, 3018..3021, 3024, 3031, 3046..3066),
    'telugu' => ranges_to_unicode(3072..3075, 3077..3084, 3086..3088, 3090..3112, 3114..3129, 3133..3140, 3142..3144, 3146..3149, 3157..3158, 3160..3161, 3168..3171, 3174..3183, 3192..3199),
    'thaana' => ranges_to_unicode(1920..1969),
    'thai' => ranges_to_unicode(3585..3642, 3648..3675),
    'tibetan' => ranges_to_unicode(3840..3911, 3913..3948, 3953..3972),
    'tifinagh' => ranges_to_unicode(11568..11623, 11631..11632, 11647),
    'ugaritic' => ranges_to_unicode(),
    'vai' => ranges_to_unicode(42240..42367),
    'yi' => ranges_to_unicode(40960..41087),
  }.freeze
end

