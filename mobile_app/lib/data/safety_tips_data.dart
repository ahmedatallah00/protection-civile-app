class SafetyTip {
  final String title;
  final String category;
  final String description;
  final List<String> dos;
  final List<String> donts;
  final String iconName;

  // Arabic fields
  final String titleAr;
  final String categoryAr;
  final String descriptionAr;
  final List<String> dosAr;
  final List<String> dontsAr;

  SafetyTip({
    required this.title,
    required this.category,
    required this.description,
    required this.dos,
    required this.donts,
    required this.iconName,
    required this.titleAr,
    required this.categoryAr,
    required this.descriptionAr,
    required this.dosAr,
    required this.dontsAr,
  });
}

final List<SafetyTip> safetyTipsData = [
  SafetyTip(
    title: 'Incendie Domestique',
    category: 'Incendie',
    description: 'Que faire en cas de départ de feu à la maison.',
    iconName: 'local_fire_department',
    dos: [
      'Évacuez immédiatement les lieux en fermant la porte de la pièce en feu.',
      'Si de la fumée commence à envahir la pièce, baissez-vous près du sol où l\'air est plus sain.',
      'Appelez le 198 (Protection Civile) dès que vous êtes en sécurité.',
      'Touchez les portes avant de les ouvrir : si elles sont chaudes, ne les ouvrez pas.',
    ],
    donts: [
      'Ne prenez jamais l\'ascenseur, utilisez toujours les escaliers.',
      'Ne retournez jamais dans un bâtiment en feu pour récupérer des objets personnels.',
      'N\'ouvrez pas une porte chaude ou de laquelle s\'échappe de la fumée.',
      'Ne jetez pas d\'eau sur un feu d\'huile ou de graisse (cuisine).',
    ],
    titleAr: 'الحريق المنزلي',
    categoryAr: 'حرائق',
    descriptionAr: 'ماذا تفعل في حالة نشوب حريق في المنزل وكيفية حماية نفسك.',
    dosAr: [
      'غادر المكان فوراً مع إغلاق باب الغرفة المشتعلة لمنع انتشار النيران.',
      'إذا بدأ الدخان يملأ الغرفة، انخفض بالقرب من الأرض حيث يكون الهواء أنقى.',
      'اتصل بالرقم 198 (الحماية المدنية) بمجرد وصولك إلى مكان آمن.',
      'المس الأبواب قبل فتحها: إذا كانت ساخنة، فلا تفتحها أبداً.',
    ],
    dontsAr: [
      'لا تستخدم المصعد أبداً عند الإخلاء، استخدم السلالم دائماً.',
      'لا تعد أبداً إلى مبنى محترق لاستعادة أغراضك الشخصية.',
      'لا تفتح باباً ساخناً أو يتصاعد منه الدخان لتجنب هبوب النيران المفاجئ.',
      'لا تسكب الماء على حريق ناتج عن الزيوت أو الدهون (حرائق المطبخ).',
    ],
  ),
  SafetyTip(
    title: 'Inondation',
    category: 'Inondation',
    description: 'Consignes de sécurité en cas de montée rapide des eaux ou de pluies diluviennes.',
    iconName: 'water_damage',
    dos: [
      'Réfugiez-vous en hauteur (à l\'étage ou sur le toit si nécessaire).',
      'Coupez le gaz et l\'électricité pour éviter les courts-circuits et les explosions.',
      'Suivez les consignes de sécurité diffusées à la radio ou par la Protection Civile.',
      'Préparez un kit d\'urgence (eau, nourriture, médicaments, lampe de poche).',
    ],
    donts: [
      'Ne descendez jamais dans les sous-sols ou les parkings souterrains.',
      'Ne traversez pas une route inondée à pied ou en voiture (30 cm d\'eau suffisent à emporter un véhicule).',
      'Ne touchez pas aux équipements électriques mouillés.',
      'Ne buvez pas l\'eau du robinet sans être sûr de sa potabilité.',
    ],
    titleAr: 'الفيضانات',
    categoryAr: 'فيضانات',
    descriptionAr: 'إرشادات السلامة في حالة الارتفاع السريع لمنسوب المياه أو الأمطار الغزيرة.',
    dosAr: [
      'الجأ إلى مكان مرتفع (الطابق العلوي أو السطح إذا لزم الأمر).',
      'اقطع الغاز والكهرباء لتجنب الماس الكهربائي وحوادث الصعق والانفجارات.',
      'اتبع تعليمات السلامة المذاعة عبر الراديو أو من قبل الحماية المدنية.',
      'جهّز حقيبة طوارئ تحتوي على ماء، طعام، أدوية، ومصباح يدوي.',
    ],
    dontsAr: [
      'لا تنزل أبداً إلى الطوابق السفلية أو مواقف السيارات تحت الأرض أثناء الفيضان.',
      'لا تعبر طريقاً مغموراً بالمياه مشياً أو بالسيارة (30 سم من الماء كافية لجرف سيارتك).',
      'لا تلمس الأجهزة أو التوصيلات الكهربائية المبللة أبداً.',
      'لا تشرب مياه الحنفية دون التأكد من تعقيمها وصلاحيتها للشرب.',
    ],
  ),
  SafetyTip(
    title: 'Vague de Chaleur / Canicule',
    category: 'Météo',
    description: 'Comment se protéger et protéger ses proches lors de températures extrêmes.',
    iconName: 'wb_sunny',
    dos: [
      'Buvez de l\'eau régulièrement sans attendre d\'avoir soif.',
      'Maintenez votre logement au frais en fermant les volets le jour et en ouvrant la nuit.',
      'Mouillez votre corps et utilisez un ventilateur ou climatiseur.',
      'Prenez régulièrement des nouvelles des personnes âgées ou isolées.',
    ],
    donts: [
      'Évitez de sortir aux heures les plus chaudes de la journée (12h - 16h).',
      'Ne faites pas d\'efforts physiques intenses en plein soleil.',
      'Ne consommez pas d\'alcool ni de boissons fortes en caféine ou sucre.',
      'Ne laissez jamais une personne ou un animal seul dans une voiture garée au soleil.',
    ],
    titleAr: 'موجة الحر شديدة / القرة',
    categoryAr: 'طقس',
    descriptionAr: 'كيف تحمي نفسك وعائلتك عند ارتفاع درجات الحرارة إلى مستويات قياسية.',
    dosAr: [
      'اشرب الماء بانتظام وبكميات كافية دون انتظار الشعور بالعطش.',
      'حافظ على برودة مسكنك بإغلاق النوافذ والستائر نهاراً وفتحها ليلاً.',
      'بلل جسمك بالماء البارد واستخدم مروحة أو مكيف هواء.',
      'تفقّد بانتظام جيرانك وكبار السن والأشخاص الذين يعيشون بمفردهم.',
    ],
    dontsAr: [
      'تجنب الخروج في أشد أوقات اليوم حراً (من الساعة 12 ظهراً إلى 4 مساءً).',
      'لا تقم بأنشطة بدنية شاقة أو تمارين تحت أشعة الشمس المباشرة.',
      'تجنب المشروبات الغنية بالكافيين أو السكريات لأنها تزيد الجفاف.',
      'لا تترك أحداً (ولا سيما الأطفال أو الحيوانات) في سيارة مغلقة متوقفة تحت الشمس.',
    ],
  ),
  SafetyTip(
    title: 'Secourisme : Arrêt Cardiaque',
    category: 'Sauvetage',
    description: 'Les gestes simples qui sauvent en attendant l\'arrivée des secours.',
    iconName: 'favorite',
    dos: [
      'Vérifiez la respiration de la victime (regardez si la poitrine se soulève).',
      'Appelez ou faites appeler immédiatement le SAMU (190) ou la Protection Civile (198).',
      'Débutez le massage cardiaque (100 à 120 compressions par minute au centre de la poitrine).',
      'Utilisez un défibrillateur automatique (DAE) si un appareil est disponible.',
    ],
    donts: [
      'Ne perdez pas de temps à essayer de prendre le pouls si la personne ne réagit pas et ne respire pas.',
      'N\'interrompez pas le massage cardiaque avant l\'arrivée des secours, sauf fatigue extrême.',
      'Ne donnez rien à boire ou à manger à une personne inconsciente.',
    ],
    titleAr: 'الإسعافات الأولية: السكتة القلبية',
    categoryAr: 'إنقاذ',
    descriptionAr: 'خطوات بسيطة وسريعة لإنقاذ حياة المصاب في انتظار وصول فرق الإسعاف.',
    dosAr: [
      'تحقق فوراً من تنفس الضحية (انظر هل يرتفع الصدر وينخفض).',
      'اتصل فوراً بالرقم 190 (SAMU) أو الحماية المدنية (198) للإبلاغ عن الحالة.',
      'ابدأ بعملية التدليك القلبي (100 إلى 120 ضغطة في الدقيقة في منتصف الصدر).',
      'استخدم جهاز إزالة الرجفان الخارجي الآلي (AED) إذا كان متوفراً بالقرب منك.',
    ],
    dontsAr: [
      'لا تضع الوقت في محاولة قياس النبض إذا كان الشخص لا يستجيب ولا يتنفس.',
      'لا توقف التدليك القلبي قبل وصول المسعفين إلا في حالة التعب الشديد أو تحرك المصاب.',
      'لا تعطِ أي شيء للأكل أو الشرب لشخص غائب عن الوعي لتجنب الاختناق.',
    ],
  ),
  SafetyTip(
    title: 'Tempête de Sable / Vent Fort',
    category: 'Météo',
    description: 'Recommandations lors de tempêtes de sable ou de rafales de vents violents.',
    iconName: 'wind_power',
    dos: [
      'Restez à l\'intérieur et fermez hermétiquement toutes les portes et fenêtres.',
      'Portez un masque ou un tissu humide sur la bouche et le nez si vous devez sortir.',
      'Si vous conduisez, garez-vous sur le côté de la route en allumant vos feux de détresse.',
      'Fixez ou rangez les objets extérieurs susceptibles d\'être emportés par le vent.',
    ],
    donts: [
      'N\'essayez pas de conduire si la visibilité est nulle.',
      'Ne vous abritez pas sous des arbres, des lignes électriques ou des structures légères.',
      'Évitez d\'utiliser les climatiseurs qui aspirent l\'air extérieur chargé de sable.',
    ],
    titleAr: 'العواصف الرملية / الرياح القوية',
    categoryAr: 'طقس',
    descriptionAr: 'توصيات وتوجيهات السلامة عند هبوب العواصف الرملية أو رياح عاتية.',
    dosAr: [
      'ابقَ داخل المنزل وأغلق جميع الأبواب والنوافذ بإحكام لمنع دخول الغبار.',
      'ارتدِ كمامة أو قطعة قماش مبللة على الفم والأنف لحماية جهازك التنفسي إذا اضطررت للخروج.',
      'إذا كنت تقود، اركن سيارتك بأمان على جانب الطريق مع تشغيل أضواء التنبيه.',
      'قم بتثبيت أو إدخال جميع الأغراض الخارجية التي يمكن أن تذروها وتطير بها الرياح.',
    ],
    dontsAr: [
      'لا تحاول مواصلة القيادة إذا انعدمت الرؤية تماماً بسبب الغبار والرمال.',
      'لا تحتمِ ولا تقف تحت الأشجار، أو خطوط الكهرباء، أو لوحات الإعلانات المعرضة للسقوط.',
      'تجنب تشغيل أجهزة التكييف التي تسحب الهواء من الخارج لتجنب امتلاء المنزل بالغبار.',
    ],
  ),
];
