%% kpithesis.cls
%%
%% Фаза 1 (мінімальна версія): сторінка, шрифти, мова.
%% Кожне рішення тут детально пояснене в docs/ARCHITECTURE.md --
%% якщо незрозуміло, чому зроблено саме так, дивіться там.

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{kpithesis}[2026/09/19 v0.1 KPI thesis class]

% --- Ступінь: бакалавр чи магістр? ---
% Це ЄДИНА річ, яку клас розрізняє за допомогою опції (а не факультет,
% не кафедра, не спеціальність -- усе це просто дані в config.tex).
% Ступінь впливає на вигляд титульної сторінки й бланку завдання
% (магістерській дисертації потрібні ще УДК і "На правах рукопису",
% яких немає в бакалаврській роботі) -- див. titlepages/.
% Використання: \documentclass[master]{kpithesis} або [bachelor].
% Типове значення -- master, оскільки це основний сценарій використання
% цього шаблону.
\newif\ifkpithesis@Master
\DeclareOption{bachelor}{\kpithesis@Masterfalse}
\DeclareOption{master}{\kpithesis@Mastertrue}
\ExecuteOptions{master}
\ProcessOptions\relax

% Базовий клас "report" дає ієрархію \chapter -> \section -> \subsection,
% яка відповідає вимогам ДСТУ 3008:2015 до розділів/підрозділів/пунктів.
% Кегль 14pt задаємо одразу тут (п. 7.1.5 стандарту) -- але через
% "extreport" (пакет extsizes), а не звичайний "report": стандартні
% класи LaTeX (article/report/book) розуміють як розмір шрифта лише
% 10pt/11pt/12pt, тож "14pt" вони мовчки ІГНОРУЮТЬ (текст залишився б
% 10-пунктовим, хоч і без явної помилки -- підступна пастка). extreport
% -- це той самий report, тільки з підтримкою додаткових розмірів,
% зокрема 14pt.
\LoadClass[a4paper, 14pt]{extreport}

% --- Двигун компіляції ---
% Цей клас навмисно працює ЛИШЕ з XeLaTeX. pdfLaTeX не вміє звертатися
% до системних шрифтів напряму (звідси історичні проблеми зі шрифтами
% на кшталт PSCyr), а XeLaTeX/LuaLaTeX вміють. Я обрав саме XeLaTeX
% (не LuaLaTeX) -- пояснення чому саме так у docs/ARCHITECTURE.md.
% Якщо хтось випадково запустить pdflatex, компіляція одразу
% зупиниться з людяним повідомленням про помилку, а не незрозумілим
% нагромадженням помилок кодування.
\RequirePackage{iftex}
\RequireXeTeX

% --- Шрифти ---
% fontspec дозволяє підключати системні TrueType/OpenType шрифти за
% назвою -- саме те, чого бракувало pdfLaTeX.
\RequirePackage{fontspec}

% --- Мова ---
% polyglossia -- сучасний пакет мовної підтримки для XeLaTeX/LuaLaTeX,
% на відміну від застарілого babel не вимагає підключати "russian" як
% проміжну залежність для роботи з кирилицею.
\RequirePackage{polyglossia}
\setdefaultlanguage{ukrainian}
\setotherlanguage{english}

% --- Основний шрифт (ДСТУ 3008:2015, п. 7.1.5: Times New Roman) ---
% Спершу пробуємо системний "Times New Roman" -- він є, якщо на
% комп'ютері встановлено Microsoft Office (Windows/macOS). Якщо його
% немає (наприклад, "чистий" Linux без Office, чи сервер Overleaf/
% GitHub Actions) -- автоматично використовуємо шрифт із теки fonts/,
% що йде разом із шаблоном: Liberation Serif. Це метрично сумісний (та
% сама ширина літер) замінник Times New Roman з відкритою ліцензією
% OFL і повною підтримкою кирилиці -- без потреби ставити щось вручну.
%
% Тут є нюанс, виявлений під час тестування шаблону: перевірки "шрифт
% з такою назвою існує" НЕДОСТАТНЬО. У деяких системах (наприклад,
% Linux із пакетом mscorefonts) шрифт "Times New Roman" присутній, але
% це стара версія БЕЗ кириличних гліфів узагалі -- компіляція впаде на
% \begin{document} з незрозумілою для новачка помилкою пакета
% polyglossia. Тому ми додатково перевіряємо, чи містить кандидат
% кирилицю, тим самим механізмом (\fontspec_if_script:nTF), яким для
% цього ж самого користується сама polyglossia -- тобто просто
% виконуємо цю перевірку РАНІШЕ і самі вирішуємо, що робити, замість
% того, щоб компіляція аварійно зупинялася.
% \fontspec_if_script:nTF -- це команда "мови" expl3 (сучасного
% внутрішнього діалекту LaTeX, яким написані і fontspec, і
% polyglossia): у ній підкреслення "_" і двокрапка ":" є частиною імен
% команд, а не звичайними символами, і TeX повинен знати про це ще на
% етапі ЧИТАННЯ файлу. Якщо написати такий виклик просто всередині
% аргументу іншої команди (наприклад, \IfFontExistsTF{...}{ОСЬ ТУТ}{}),
% TeX встигає "розібрати" цей аргумент на токени ще до того, як
% \ExplSyntaxOn взагалі спрацює -- і "розсипає" ім'я команди на окремі
% символи, видаючи лавину незрозумілих помилок (це не гіпотетично:
% саме так і сталося при первинному тестуванні шаблону). Тому таку
% перевірку означуємо ОКРЕМОЮ командою тут, одразу після
% \ExplSyntaxOn -- тоді ім'я "запікається" правильно один раз, а
% викликати готову команду \kpithesis@CheckCyrillic можна вже звідки
% завгодно, без цієї пастки.
\ExplSyntaxOn
\cs_new_protected:Npn \kpithesis@CheckCyrillic #1
  {
    \group_begin:
      #1
      \fontspec_if_script:nTF {cyrl}
        { \global\kpithesis@CyrillicOKtrue }
        { \global\kpithesis@CyrillicOKfalse }
    \group_end:
  }
\ExplSyntaxOff

\newif\ifkpithesis@CyrillicOK
\IfFontExistsTF{Times New Roman}
  {
    \newfontfamily\kpithesis@CandidateFont{Times New Roman}
    \kpithesis@CheckCyrillic{\kpithesis@CandidateFont}
  }
  {\kpithesis@CyrillicOKfalse}

% ДСТУ 3008 вимагає лише ОДИН шрифт (Times New Roman) для всього
% тексту -- окремого моношрифту для лістингів код чи "рублений" шрифт
% (sans-serif) стандарт не передбачає. Але polyglossia все одно
% перевіряє кирилицю в ролях "monospace" і "sans" (наприклад, коли
% biblatex друкує URL моношрифтом через \url) -- якщо їх не задати
% явно, вони мовчки залишаться на застарілому "Latin Modern" без
% кирилиці, і компіляція впаде так само, як і з основним шрифтом
% раніше. Тому призначаємо їм ТОЙ САМИЙ, уже перевірений шрифт.
\ifkpithesis@CyrillicOK
  \setmainfont{Times New Roman}
  \setsansfont{Times New Roman}
  \setmonofont{Times New Roman}
\else
  % Файли названо без пробілу (LiberationSerif-*.ttf), тому шляхи
  % задаємо напряму, а не через шаблон "*" (який підставив би сюди
  % назву шрифта РАЗОМ із пробілом -- "Liberation Serif-Regular" --
  % і файл не знайшовся б).
  \setmainfont{Liberation Serif}[
    Path = fonts/,
    UprightFont = LiberationSerif-Regular.ttf,
    BoldFont = LiberationSerif-Bold.ttf,
    ItalicFont = LiberationSerif-Italic.ttf,
    BoldItalicFont = LiberationSerif-BoldItalic.ttf,
  ]
  \setsansfont{Liberation Serif}[
    Path = fonts/,
    UprightFont = LiberationSerif-Regular.ttf,
    BoldFont = LiberationSerif-Bold.ttf,
    ItalicFont = LiberationSerif-Italic.ttf,
    BoldItalicFont = LiberationSerif-BoldItalic.ttf,
  ]
  \setmonofont{Liberation Serif}[
    Path = fonts/,
    UprightFont = LiberationSerif-Regular.ttf,
    BoldFont = LiberationSerif-Bold.ttf,
    ItalicFont = LiberationSerif-Italic.ttf,
    BoldItalicFont = LiberationSerif-BoldItalic.ttf,
  ]
\fi

% --- Поля сторінки (ДСТУ 3008:2015, п. 7.1.11) ---
% Стандарт задає МІНІМАЛЬНІ береги: верхній/нижній -- не менше 20 мм,
% лівий -- не менше 25 мм, правий -- не менше 10 мм. Використовуємо ці
% значення як усталені (мінімально допустимі й водночас найпоширеніші).
\RequirePackage[a4paper, top=20mm, bottom=20mm, left=25mm, right=10mm]{geometry}

% --- Міжрядковий інтервал (п. 7.1.5: 1,5--2 інтервали) ---
\RequirePackage{setspace}
\onehalfspacing

% --- Абзацний відступ (п. 7.1.22: 5 знаків = 1,25 см) ---
\setlength{\parindent}{1.25cm}

% ************************************************************* %
%  Фаза 2: заголовки, зміст, підписи, переліки, нумерація формул,
%  додатки -- тобто безпосередньо "тіло" вимог ДСТУ 3008:2015.
% ************************************************************* %

% --- Заголовки розділів і підрозділів ---
% titlesec дозволяє повністю переозначити вигляд \chapter/\section/
% \subsection, не залізаючи у внутрішню кухню базового класу.
\RequirePackage{titlesec}

% Розділи (п. 7.1.20): ВЕЛИКІ ЛІТЕРИ, напівжирний, по центру, без
% крапки в кінці; номер -- просто число, без крапки після нього.
\titleformat{\chapter}
  {\centering\bfseries\MakeUppercase}
  {\thechapter}
  {0.5em}
  {}
% Відступ від тексту (п. 7.1.24): не менше 2 міжрядкових інтервалів
% і до, і після заголовка.
\titlespacing{\chapter}{0pt}{0pt}{2\baselineskip}

% Підрозділи й пункти (п. 7.1.21): з абзацного відступу, звичайний
% регістр (велика лише перша літера), напівжирний, без крапки.
\titleformat{\section}
  {\bfseries}
  {\thesection}
  {0.5em}
  {}
\titlespacing{\section}{\parindent}{2\baselineskip}{2\baselineskip}

\titleformat{\subsection}
  {\bfseries}
  {\thesubsection}
  {0.5em}
  {}
\titlespacing{\subsection}{\parindent}{2\baselineskip}{2\baselineskip}

% --- Ненумеровані структурні елементи (п. 7.1.18) ---
% "Реферат", "Зміст", "Вступ", "Висновки", "Перелік посилань" тощо
% оформлюють як заголовок розділу (той самий стиль), але БЕЗ номера і
% без нумерації в тексті -- хоча вони й потрапляють у Зміст.
\newcommand{\kpithesisUnnumberedChapter}[1]{%
  \chapter*{#1}%
  \addcontentsline{toc}{chapter}{#1}%
}

% "Висновки до розділу N" -- підсумок наприкінці кожного розділу
% магістерської дисертації (див. Рекомендації КПІ, розділ "Основна
% частина"). Це ненумерований підрозділ, який усе ж додають до Змісту.
\newcommand{\kpithesisChapterConclusion}[1]{%
  \section*{Висновки до розділу #1}%
  \addcontentsline{toc}{section}{Висновки до розділу #1}%
}

% --- Зміст (Додаток Б стандарту) ---
% tocloft керує виглядом автоматично зібраного змісту: заповнення
% крапками до номера сторінки, відступи для розділів/підрозділів.
\RequirePackage[titles]{tocloft}
\renewcommand{\cftchapfont}{\mdseries}
\renewcommand{\cftchappagefont}{\mdseries}
\renewcommand{\cftsecindent}{1.5em}
\setlength{\cftbeforechapskip}{0pt}

% --- Рисунки й таблиці (п. 7.5, 7.6) ---
% Рисунок: підпис ПІД зображенням, по центру ("Рисунок N — Назва").
% Таблиця: підпис НАД таблицею, зліва ("Таблиця N — Назва").
% Обидва нумеруємо в межах розділу (номер = "розділ.порядковий" --
% п. 7.5.6/7.6.4 дозволяють такий варіант), як і формули нижче.
\RequirePackage{graphicx}
\RequirePackage{caption}
% amsmath дає команду \numberwithin, якою ми користуємось і для
% рисунків/таблиць одразу нижче, і для формул трохи далі -- тому
% підключаємо його тут, ще до першого використання.
\RequirePackage{amsmath}
\DeclareCaptionLabelSeparator{kpithesisDash}{ --- }
\captionsetup[figure]{
  position = below,
  justification = centering,
  labelsep = kpithesisDash,
  name = Рисунок,
}
\captionsetup[table]{
  position = above,
  justification = raggedright,
  labelsep = kpithesisDash,
  name = Таблиця,
  singlelinecheck = false,
}
\numberwithin{figure}{chapter}
\numberwithin{table}{chapter}

% --- Формули (п. 7.10) ---
% Номер формули праворуч, у дужках -- це поведінка LaTeX за
% замовчуванням для \begin{equation}, тож додаткового форматування не
% потрібно. Нумеруємо в межах розділу, як дозволяє п. 7.10.3.
\numberwithin{equation}{chapter}

% --- Переліки (п. 7.7) ---
% Найпростіший, найпоширеніший випадок: ненумерований перелік одного
% рівня без перехресних посилань позначають тире "--" (не крапкою і
% не стандартним LaTeX-маркером "•").
\RequirePackage{enumitem}
\setlist[itemize]{label=--}

% --- Додатки (п. 6.2, 7.15) ---
% Додатки позначають великими літерами української абетки, ПРОПУСКАЮЧИ
% Ґ, Є, З, І, Ї, Й, О, Ч, Ь (п. 7.15.1) -- бо ці літери легко сплутати
% з іншими позначеннями або цифрами. Тому це не звичайний \alph, а
% ручний список саме дозволених літер.
\newcounter{kpithesis@AppendixNum}
\newcommand{\kpithesis@AppendixLetter}{%
  \ifcase\value{kpithesis@AppendixNum}%
  \or А\or Б\or В\or Г\or Д\or Е\or Ж\or И\or К\or Л\or М\or Н%
  \or П\or Р\or С\or Т\or У\or Ф\or Х\or Ц\or Ш\or Щ\or Ю\or Я%
  \else ?% більше 24 додатків шаблон не підтримує (і навряд чи знадобиться🌚)
  \fi
}

% \kpithesisAppendix{Назва додатка} -- починає новий додаток.
% Перевизначаючи \thechapter на літеру додатка, ми "безкоштовно"
% отримуємо правильну нумерацію рисунків/таблиць/формул усередині
% додатка (В.1, В.2...) -- бо їхні \theX-формати вище вже посилаються
% на \thechapter, а не захищений від цього номер розділу.
\newcommand{\kpithesisAppendix}[1]{%
  \stepcounter{kpithesis@AppendixNum}%
  \setcounter{figure}{0}%
  \setcounter{table}{0}%
  \setcounter{equation}{0}%
  \renewcommand{\thechapter}{\kpithesis@AppendixLetter}%
  % Заголовок додатка -- це буквально ДВА рядки (слово "ДОДАТОК" з
  % літерою, і окремо власна назва додатка звичайним накресленням).
  % \chapter* приймає лише "однорядковий" аргумент (він потрапляє,
  % наприклад, у колонтитул), тому \par там використати не можна --
  % другий рядок друкуємо звичайним текстом одразу після.
  \chapter*{ДОДАТОК~\kpithesis@AppendixLetter}%
  \addcontentsline{toc}{chapter}{Додаток~\kpithesis@AppendixLetter\ #1}%
  \begin{center}
    \normalfont\mdseries #1
  \end{center}
  \vspace{1em}%
}

% ************************************************************* %
%  Фаза 3: титульна сторінка й бланк завдання
% ************************************************************* %

% etoolbox дає зручну перевірку "чи це поле порожнє" -- нею
% скористаються titlepages/*.tex, щоб автоматично пропускати рядок
% консультанта, якщо його немає (див. config.tex). tabularx --
% таблиці на всю ширину сторінки з рядком, що сам переноситься --
% знадобиться для бланку завдання (Календарний план тощо).
\RequirePackage{etoolbox}
\RequirePackage{tabularx}

% Ці дві команди -- усе, що треба викликати з main.tex. Яку саме пару
% файлів з titlepages/ підключити (бакалаврську чи магістерську),
% вирішує \ifkpithesis@Master, тобто те, яку опцію класу вказано у
% \documentclass -- див. початок цього файлу.
\newcommand{\kpithesisTitlePage}{%
  \ifkpithesis@Master
    \input{titlepages/master-title.tex}%
  \else
    \input{titlepages/bachelor-title.tex}%
  \fi
}
\newcommand{\kpithesisTaskPage}{%
  \ifkpithesis@Master
    \input{titlepages/master-task.tex}%
  \else
    \input{titlepages/bachelor-task.tex}%
  \fi
}

% ************************************************************* %
%  Фаза 5: Перелік посилань (ДСТУ 8302:2015)
% ************************************************************* %
%
% ДСТУ 3008:2015 (п. 5.5.2) каже оформлювати бібліографічні описи "за
% ДСТУ ГОСТ 7.1" -- це старий, докладний стандарт для БІБЛІОТЕЧНИХ
% каталожних записів. Але "Рекомендації..." КПІ прямим текстом уточнюють,
% що саме для кваліфікаційних робіт список джерел складають за ДСТУ
% 8302:2015 -- новішим і простішим стандартом САМЕ для посилань (а не
% каталогів). Тому орієнтуємось на нього.
%
% Готового пакета "biblatex-dstu8302" не існує; є близький за духом
% "biblatex-gost" (для російського ГОСТ 7.0.5). Замість того, щоб
% брати його як залежність (він розрахований на інший, хоч і схожий,
% стандарт), ми взяли вбудований стиль biblatex "numeric" і
% донастроїли лише ті деталі, якими ДСТУ 8302 відрізняється:
%   - крапка між "зонами" опису замість повного бібліотечного ". --";
%   - "Прізвище І. Б." БЕЗ коми між прізвищем та ініціалами;
%   - порядок джерел за появою в тексті, а не за абеткою.
% Це наближення, перевірене на прикладах зі стандарту, а не переклад
% усього стандарту -- нетипові джерела (архівні документи, законодавчі
% акти тощо) варто звірити з оригіналом ДСТУ 8302:2015 вручну.
\RequirePackage[
  backend = biber,
  style = numeric,
  sorting = none,        % порядок першої згадки в тексті (п. 5.5.1 ДСТУ 3008)
  giveninits = true,     % ініціали ("І. Б."), а не повні імена
  maxnames = 3,          % ДСТУ 8302 показує до 3 авторів повністю...
  minnames = 3,          %  ...а не "перший + та ін." (типова поведінка biblatex)
]{biblatex}

% Порядок "Прізвище Ім'я" (а не типове для biblatex "Ім'я Прізвище")...
\DeclareNameAlias{author}{family-given}
% ...і без коми між ними ("Панько, Т. І." -> "Панько Т. І."):
% \revsdnamepunct це офіційний, документований гачок саме для такого
% форматування імен, коли прізвище йде першим ("reversed" name format).
\renewcommand*{\revsdnamepunct}{}

% Назву джерела ДСТУ 8302 друкує звичайним текстом -- типовий biblatex
% же виділяє назву книги курсивом, а назву статті бере в лапки. Обидва
% варіанти прибираємо, залишаючи текст як є.
\DeclareFieldFormat{title}{#1}
\DeclareFieldFormat
  [article, inbook, incollection, inproceedings, patent, thesis, unpublished]
  {title}{#1}

% Тип роботи (посібник, монографія, дисертація...) ДСТУ 8302 пише
% одразу після назви через " : " -- у .bib-записі впишіть цей текст у
% поле "subtitle" (не "type"): biblatex вже вміє друкувати subtitle
% одразу за title, лишається тільки виправити роздільник на потрібний.
\renewcommand*{\subtitlepunct}{~: }

% Перед назвою журналу typeset biblatex зазвичай вставляє слово
% "В:" ("У:") -- у прикладах ДСТУ 8302 такого немає, просто крапка й
% одразу назва журналу.
\renewbibmacro*{in:}{}

% Місце видання й видавництво ДСТУ 8302 розділяє ПРОБІЛОМ і двокрапкою
% з обох боків ("Київ : Академія"), а не типовим для biblatex
% "Київ: Академія" (пробіл лише після). \addcolon сам керує пробілами
% навколо себе (і "з'їдає" будь-який пробіл, доданий перед ним), тому
% замість нього тут просто НЕРОЗРИВНИЙ пробіл + двокрапка як звичайний
% текст -- це копія стандартного визначення з biblatex.def/standard.bbx.
\renewbibmacro*{publisher+location+date}{%
  \printlist{location}%
  \iflistundef{publisher}
    {\setunit*{\addcomma\space}}
    {\setunit*{~:~}}%
  \printlist{publisher}%
  \setunit*{\addcomma\space}%
  \usebibmacro{date}%
  \newunit}

% Статті з журналів (ДСТУ 8302, приклад): "Назва журналу. Рік. № Номер,
% С. Сторінки." -- типовий biblatex пише складніше ("Назва журналу
% Номер (Рік), сторінки"), бо орієнтований на англомовні стилі
% цитування. Спрощуємо до того, що показує ДСТУ 8302 (без серій, без
% номерів статей (eid) -- для звичайної статті в журналі вони не
% потрібні).
\renewbibmacro*{journal+issuetitle}{%
  \usebibmacro{journal}%
  \addperiod\space
  \usebibmacro{date}%
  \iffieldundef{number}
    {}
    {\addperiod\space№~\printfield{number}\addcomma\space}%
}

\addbibresource{bibliography.bib}
