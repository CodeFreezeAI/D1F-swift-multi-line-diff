# MultiLineDiff Website

This is the official website for the MultiLineDiff Swift library, showcasing its revolutionary features and capabilities.

## 🌐 Live Site

**URL**: https://diff.xcf.ai

## 📁 Project Structure

```
website/
├── index.html              # Main HTML page
├── css/
│   ├── styles.css          # Main styles and layout
│   ├── components.css      # Component-specific styles
│   └── animations.css      # Animation definitions
├── js/
│   ├── main.js            # Core functionality
│   ├── demo.js            # Interactive demo
│   └── performance.js     # Performance charts
├── images/
│   ├── favicon.svg        # Site favicon
│   ├── og-image.png       # Social media preview (to be added)
│   └── apple-touch-icon.png # iOS icon (to be added)
├── fonts/                 # Custom fonts (if needed)
└── README.md             # This file
```

## 🚀 Features

### Modern Design
- **Dark Theme**: Professional dark color scheme
- **Responsive Layout**: Works on all devices
- **Smooth Animations**: Engaging user experience
- **Performance Optimized**: Fast loading and smooth interactions

### Interactive Components
- **Algorithm Comparison**: Tabbed interface showing all 5 algorithms
- **Live Demo**: Interactive diff generation with syntax highlighting
- **Performance Charts**: Real-time performance visualization
- **Scroll Animations**: Elements animate as they come into view

### Technical Features
- **Pure HTML/CSS/JS**: No framework dependencies
- **Modern CSS**: CSS Grid, Flexbox, Custom Properties
- **ES6+ JavaScript**: Modern JavaScript features
- **Chart.js Integration**: Beautiful performance charts
- **Prism.js**: Syntax highlighting for code examples

## 🛠️ Development

### Local Development
1. Clone the repository
2. Navigate to the `website` directory
3. Serve the files using any HTTP server:

```bash
# Using Python
python -m http.server 8000

# Using Node.js
npx serve .

# Using PHP
php -S localhost:8000
```

4. Open http://localhost:8000 in your browser

### Dependencies
The website uses CDN-hosted libraries:
- **Chart.js**: Performance charts
- **Prism.js**: Syntax highlighting
- **Google Fonts**: Inter and JetBrains Mono fonts

### Browser Support
- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

## 📱 Responsive Breakpoints

- **Desktop**: 1200px+
- **Tablet**: 768px - 1199px
- **Mobile**: 320px - 767px

## 🎨 Design System

### Colors
- **Primary**: #6366f1 (Indigo)
- **Secondary**: #10b981 (Emerald)
- **Accent**: #f59e0b (Amber)
- **Background**: #0f0f23 (Dark Blue)
- **Text**: #f8fafc (Slate)

### Typography
- **Sans Serif**: Inter (Google Fonts)
- **Monospace**: JetBrains Mono (Google Fonts)

### Spacing
- **Base Unit**: 1rem (16px)
- **Scale**: 0.25, 0.5, 1, 1.5, 2, 3, 4rem

## 🚀 Deployment

### Static Hosting
The website is a static site and can be deployed to:
- **Netlify**: Drag and drop deployment
- **Vercel**: Git-based deployment
- **GitHub Pages**: Direct from repository
- **AWS S3**: Static website hosting
- **Cloudflare Pages**: Fast global deployment

### Recommended Deployment (Netlify)
1. Create account at netlify.com
2. Drag the `website` folder to Netlify dashboard
3. Configure custom domain: diff.xcf.ai
4. Enable HTTPS and CDN

### Build Optimization
For production deployment:
1. Minify CSS and JavaScript files
2. Optimize images (WebP format)
3. Enable gzip compression
4. Set up proper caching headers

## 📊 Performance

### Lighthouse Scores (Target)
- **Performance**: 95+
- **Accessibility**: 100
- **Best Practices**: 100
- **SEO**: 100

### Optimization Features
- **Lazy Loading**: Images load as needed
- **Code Splitting**: JavaScript modules
- **CSS Optimization**: Minimal unused styles
- **Font Loading**: Optimized web fonts

## 🔧 Customization

### Adding New Sections
1. Add HTML structure to `index.html`
2. Add styles to appropriate CSS file
3. Add JavaScript functionality if needed
4. Update navigation links

### Modifying Colors
Update CSS custom properties in `styles.css`:
```css
:root {
  --primary: #your-color;
  --secondary: #your-color;
  /* etc. */
}
```

### Adding Animations
Add new keyframes to `animations.css` and apply classes to elements.

## 📈 Analytics

### Recommended Analytics
- **Google Analytics 4**: User behavior tracking
- **Hotjar**: User session recordings
- **PageSpeed Insights**: Performance monitoring

### Event Tracking
The site includes event tracking for:
- Button clicks
- Section scrolling
- Demo interactions
- Algorithm selections

## 🔒 Security

### Content Security Policy
Recommended CSP headers:
```
Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' cdn.jsdelivr.net cdnjs.cloudflare.com; style-src 'self' 'unsafe-inline' fonts.googleapis.com; font-src fonts.gstatic.com; img-src 'self' data:;
```

### HTTPS
Always serve over HTTPS in production.

## 📞 Support

For website issues or suggestions:
- **Repository**: https://github.com/codefreezeai/swift-multi-line-diff
- **Email**: support@xcf.ai
- **Website**: https://xcf.ai

## 📄 License

This website is part of the MultiLineDiff project.
© 2025 Todd Bruss, XCF.ai. All rights reserved.

---

**Built with ❤️ for the MultiLineDiff community** 