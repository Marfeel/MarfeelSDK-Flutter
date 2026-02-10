class Article {
  final String id;
  final String title;
  final String subtitle;
  final String url;
  final String category;
  final int wordCount;
  final String imageUrl;
  final String body;
  final String? rs;

  const Article({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.url,
    required this.category,
    required this.wordCount,
    required this.imageUrl,
    required this.body,
    this.rs,
  });
}

const articles = [
  Article(
    id: '1',
    title: 'Post 1 Title',
    subtitle: 'Post 1 Subtitle',
    url: 'http://dev.marfeel.co/2022/11/25/article-with-video-html5/',
    category: 'media',
    wordCount: 850,
    imageUrl: 'https://placedog.net/500/350?1',
    rs: 'recirculation source',
    body:
        "The evolution of digital media has transformed how we consume content in the modern era. "
        "From the early days of print journalism to the current landscape of digital-first publications, "
        "the industry has undergone seismic shifts that continue to reshape our understanding of storytelling.\n\n"
        "In the beginning, newspapers dominated the information landscape. Readers would wake up each morning, "
        "pick up their daily paper, and spend time absorbing the news over breakfast. The ritual was simple, "
        "predictable, and deeply embedded in the cultural fabric of society. Editors curated content with care, "
        "knowing that their readers trusted them to deliver the most important stories of the day.\n\n"
        "The arrival of the internet changed everything. Suddenly, information was available at the click of a button. "
        "News cycles accelerated from daily to hourly to minute-by-minute. The concept of breaking news evolved from "
        "a rare interruption of regular programming to a constant stream of updates flowing through social media feeds "
        "and push notifications.\n\n"
        "Publishers found themselves in an arms race for attention. The metrics that defined success shifted from "
        "circulation numbers to page views, unique visitors, and engagement rates. Content strategies evolved to "
        "prioritize discoverability and shareability, sometimes at the expense of depth and nuance.\n\n"
        "Yet amid this transformation, the fundamental principles of good journalism remained unchanged. "
        "Accuracy, fairness, and a commitment to serving the public interest continued to distinguish quality "
        "publications from the noise. The best digital media organizations found ways to honor these principles "
        "while embracing the possibilities of new technology.\n\n"
        "Mobile devices added another layer of complexity. With smartphones becoming the primary gateway to digital "
        "content, publishers had to rethink everything from page layout to advertising formats. The small screen "
        "demanded concise, visually compelling storytelling that could capture attention in seconds.\n\n"
        "Video emerged as a dominant format, with platforms investing heavily in original programming and live "
        "streaming capabilities. Podcasts experienced a renaissance, offering long-form audio content that listeners "
        "could consume during commutes, workouts, and household chores.\n\n"
        "The economics of digital media proved challenging for many traditional publishers. Advertising revenue "
        "migrated to tech platforms, forcing news organizations to explore alternative business models including "
        "subscriptions, memberships, events, and philanthropic funding.\n\n"
        "Looking ahead, artificial intelligence promises to reshape the industry once again. From automated content "
        "generation to personalized news feeds, AI technologies are creating both opportunities and ethical challenges "
        "that the industry must navigate carefully.\n\n"
        "The future of digital media will likely be defined by those organizations that can balance innovation with "
        "integrity, using technology to enhance rather than replace the human judgment that lies at the heart of "
        "great journalism. The story of media transformation is far from over — in many ways, it is just beginning.",
  ),
  Article(
    id: '2',
    title: 'Post 2 Title',
    subtitle: 'Post 2 Subtitle',
    url: 'http://dev.marfeel.co/2022/07/29/hola-1/',
    category: 'general',
    wordCount: 1200,
    imageUrl: 'https://placedog.net/500/350?2',
    body:
        "Understanding user behavior has become one of the most critical challenges facing digital publishers today. "
        "As audiences fragment across platforms and devices, the ability to track, analyze, and respond to user "
        "engagement patterns determines which publications thrive and which fade into obscurity.\n\n"
        "The science of audience analytics has evolved dramatically over the past decade. Early web analytics focused "
        "primarily on simple metrics like page views and session duration. While these numbers provided a basic "
        "understanding of traffic patterns, they offered limited insight into the quality of user engagement or "
        "the effectiveness of content strategies.\n\n"
        "Modern analytics platforms have introduced far more sophisticated measurement capabilities. Scroll depth "
        "tracking, for example, reveals how far users actually read into an article, distinguishing between visitors "
        "who bounce after seeing the headline and those who consume content thoroughly. This metric alone has "
        "transformed how editors evaluate content performance.\n\n"
        "Attention time represents another breakthrough in audience measurement. Unlike simple time-on-page metrics, "
        "which can be inflated by users who leave a tab open in the background, attention time measures active "
        "engagement — the moments when a user is actually focused on and interacting with content.\n\n"
        "Recirculation metrics track how effectively content drives users deeper into a publication. When a reader "
        "finishes one article and clicks through to another, it signals both content quality and effective editorial "
        "strategy. Publications with high recirculation rates tend to build stronger reader habits over time.\n\n"
        "The concept of user segmentation has added another dimension to audience understanding. By categorizing "
        "readers based on their behavior patterns — frequency of visits, content preferences, engagement depth — "
        "publishers can tailor their strategies to serve different audience segments more effectively.\n\n"
        "Anonymous users, logged-in users, and paying subscribers each represent distinct segments with different "
        "needs and value propositions. Understanding the journey from casual visitor to loyal subscriber requires "
        "tracking user behavior across multiple sessions and touchpoints.\n\n"
        "The RFV model — measuring Recency, Frequency, and Volume — has emerged as a powerful framework for "
        "understanding audience loyalty. Users who visit recently, frequently, and consume high volumes of content "
        "represent the most engaged segment of any publication's audience.\n\n"
        "Privacy considerations have added complexity to audience analytics. With regulations like GDPR and CCPA "
        "imposing strict requirements on data collection and processing, publishers must balance their need for "
        "audience insights with their obligation to respect user privacy.\n\n"
        "Consent management has become a critical component of any analytics strategy. Publishers must clearly "
        "communicate what data they collect, how it will be used, and give users meaningful control over their "
        "privacy preferences. This transparency, while challenging to implement, ultimately builds trust with "
        "audiences and strengthens the publisher-reader relationship.",
  ),
  Article(
    id: '3',
    title: 'Post 3 Title',
    subtitle: 'Post 3 Subtitle',
    url: 'http://dev.marfeel.co/2022/07/29/corrupti-sit-vero-asperiores-ratione-non-velit/',
    category: 'tech',
    wordCount: 600,
    imageUrl: 'https://placedog.net/500/350?3',
    body:
        "The intersection of technology and creativity has given rise to a new generation of tools that are "
        "reshaping how software is built, tested, and deployed. Cross-platform frameworks, in particular, have "
        "democratized mobile development by enabling teams to build applications for multiple platforms from a "
        "single codebase.\n\n"
        "Flutter, developed by Google, represents one of the most significant advances in this space. Its widget-based "
        "architecture and hot-reload capability have attracted a rapidly growing community of developers who "
        "appreciate its productivity benefits and the quality of the applications it produces.\n\n"
        "The framework's approach to rendering is fundamentally different from its competitors. Rather than wrapping "
        "native UI components, Flutter draws every pixel directly using its own rendering engine. This gives "
        "developers precise control over the visual appearance of their applications across platforms.\n\n"
        "Plugin development in Flutter follows a well-defined pattern. The platform channel mechanism enables Dart "
        "code to communicate with native code on both Android and iOS, providing access to platform-specific APIs "
        "and capabilities that are not available through the framework's core libraries.\n\n"
        "The method channel, the most commonly used type of platform channel, supports asynchronous message passing "
        "between Dart and native code. Messages are encoded using a standard codec that handles the serialization "
        "and deserialization of common data types automatically.\n\n"
        "Testing is a critical part of the Flutter development workflow. The framework provides a comprehensive "
        "testing infrastructure that supports unit tests, widget tests, and integration tests. Each level of "
        "testing serves a different purpose and offers different trade-offs between speed and fidelity.\n\n"
        "State management remains one of the most actively debated topics in the Flutter community. From simple "
        "setState calls to sophisticated solutions like BLoC, Riverpod, and Redux, developers have a wide range "
        "of options for managing application state. The best choice depends on the complexity of the application "
        "and the preferences of the development team.\n\n"
        "Performance optimization in Flutter requires understanding both the framework's rendering pipeline and "
        "the characteristics of the underlying platform. Common performance pitfalls include unnecessary widget "
        "rebuilds, expensive computations on the main thread, and inefficient use of images and animations.\n\n"
        "The Flutter ecosystem continues to grow rapidly, with thousands of packages available through pub.dev "
        "covering everything from network communication to advanced animations. This rich ecosystem enables "
        "developers to build sophisticated applications without reinventing common functionality.",
  ),
  Article(
    id: '4',
    title: 'Post 4 Title',
    subtitle: 'Post 4 Subtitle',
    url: 'http://dev.marfeel.co/2022/06/28/consectetur-consequuntur-quis-nobis-quia/',
    category: 'finance',
    wordCount: 950,
    imageUrl: 'https://placedog.net/500/350?4',
    body:
        "The global financial landscape is undergoing a period of unprecedented transformation driven by "
        "technological innovation, regulatory evolution, and shifting consumer expectations. Digital currencies, "
        "decentralized finance, and embedded financial services are challenging traditional banking models and "
        "creating new opportunities for both incumbents and disruptors.\n\n"
        "Central banks around the world are exploring the possibility of issuing digital currencies, a development "
        "that could fundamentally alter the architecture of the global financial system. These central bank digital "
        "currencies, or CBDCs, promise to combine the efficiency of digital payments with the stability and trust "
        "associated with government-backed money.\n\n"
        "Meanwhile, the fintech sector continues to attract significant investment as startups and established "
        "technology companies alike seek to capture market share in areas traditionally dominated by banks. Payment "
        "processing, lending, insurance, and wealth management are all being reimagined through the lens of "
        "technology-first thinking.\n\n"
        "Open banking initiatives, which require financial institutions to share customer data with authorized "
        "third parties through secure APIs, are fostering innovation and competition across the industry. These "
        "regulations are enabling a new generation of financial products and services that aggregate data from "
        "multiple providers to deliver more personalized and comprehensive solutions.\n\n"
        "The rise of embedded finance is blurring the boundaries between financial services and other industries. "
        "E-commerce platforms, ride-sharing apps, and software companies are increasingly offering financial "
        "products directly to their users, creating seamless experiences that eliminate the need to interact with "
        "traditional financial institutions.\n\n"
        "Environmental, social, and governance considerations are becoming central to investment decisions. "
        "Sustainable finance has moved from a niche concern to a mainstream priority, with investors increasingly "
        "demanding transparency about the environmental and social impact of their portfolios.\n\n"
        "The democratization of investing through commission-free trading platforms and fractional share ownership "
        "has brought millions of new participants into the financial markets. This trend has significant implications "
        "for market dynamics, corporate governance, and financial literacy.\n\n"
        "Cybersecurity remains a critical concern for the financial industry. As digital transactions proliferate "
        "and financial services become increasingly interconnected, the potential impact of security breaches grows "
        "correspondingly. Financial institutions invest billions annually in cybersecurity infrastructure and "
        "talent to protect their customers and their operations.\n\n"
        "Looking forward, the convergence of artificial intelligence, big data, and cloud computing promises to "
        "unlock new capabilities in areas like risk assessment, fraud detection, and customer service. These "
        "technologies are enabling financial institutions to process vast amounts of data in real time, delivering "
        "insights and services that were previously impossible.",
  ),
];

const videoItem = (
  id: 'UbjLtXKEE-I',
  provider: 'youtube',
  providerId: 'UbjLtXKEE-I',
  title: 'Sample Video',
  duration: 120,
);
