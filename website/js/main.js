// Main JavaScript for MultiLineDiff Website
document.addEventListener('DOMContentLoaded', function() {
    // Initialize all components
    initNavigation();
    initScrollAnimations();
    initAlgorithmTabs();
    initSmoothScrolling();
    initIntersectionObserver();
    initParallaxEffects();
    initTypewriterEffect();
    initLoadingStates();
    initShowcaseInteractions();
});

// Navigation functionality
function initNavigation() {
    const navbar = document.querySelector('.navbar');
    const navToggle = document.getElementById('nav-toggle');
    const navMenu = document.getElementById('nav-menu');
    const navLinks = document.querySelectorAll('.nav-link');

    // Mobile menu toggle
    if (navToggle && navMenu) {
        navToggle.addEventListener('click', () => {
            navMenu.classList.toggle('active');
            navToggle.classList.toggle('active');
            
            // Animate hamburger menu
            const spans = navToggle.querySelectorAll('span');
            spans.forEach((span, index) => {
                span.style.transform = navToggle.classList.contains('active') 
                    ? `rotate(${index === 0 ? 45 : index === 1 ? 0 : -45}deg) translate(${index === 1 ? '100%' : '0'}, ${index === 0 ? '6px' : index === 2 ? '-6px' : '0'})`
                    : 'none';
                span.style.opacity = index === 1 && navToggle.classList.contains('active') ? '0' : '1';
            });
        });
    }

    // Close mobile menu when clicking on links
    navLinks.forEach(link => {
        link.addEventListener('click', () => {
            if (navMenu.classList.contains('active')) {
                navMenu.classList.remove('active');
                navToggle.classList.remove('active');
            }
        });
    });

    // Navbar scroll effect
    let lastScrollY = window.scrollY;
    
    window.addEventListener('scroll', () => {
        const currentScrollY = window.scrollY;
        
        if (navbar) {
            // Add/remove scrolled class
            if (currentScrollY > 50) {
                navbar.classList.add('scrolled');
            } else {
                navbar.classList.remove('scrolled');
            }
            
            // Hide/show navbar on scroll
            if (currentScrollY > lastScrollY && currentScrollY > 100) {
                navbar.style.transform = 'translateY(-100%)';
            } else {
                navbar.style.transform = 'translateY(0)';
            }
        }
        
        lastScrollY = currentScrollY;
    });

    // Active nav link highlighting
    const sections = document.querySelectorAll('section[id]');
    
    window.addEventListener('scroll', () => {
        const scrollPosition = window.scrollY + 100;
        
        sections.forEach(section => {
            const sectionTop = section.offsetTop;
            const sectionHeight = section.offsetHeight;
            const sectionId = section.getAttribute('id');
            const navLink = document.querySelector(`.nav-link[href="#${sectionId}"]`);
            
            if (scrollPosition >= sectionTop && scrollPosition < sectionTop + sectionHeight) {
                navLinks.forEach(link => link.classList.remove('active'));
                if (navLink) navLink.classList.add('active');
            }
        });
    });
}

// Scroll animations
function initScrollAnimations() {
    const animatedElements = document.querySelectorAll('.scroll-fade-in, .scroll-slide-left, .scroll-slide-right, .scroll-scale-in');
    
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('in-view');
                observer.unobserve(entry.target);
            }
        });
    }, observerOptions);
    
    animatedElements.forEach(element => {
        observer.observe(element);
    });
}

// Algorithm tabs functionality
function initAlgorithmTabs() {
    const tabButtons = document.querySelectorAll('.tab-button');
    const algorithmPanels = document.querySelectorAll('.algorithm-panel');
    
    tabButtons.forEach(button => {
        button.addEventListener('click', () => {
            const targetAlgorithm = button.getAttribute('data-algorithm');
            
            // Remove active class from all buttons and panels
            tabButtons.forEach(btn => btn.classList.remove('active'));
            algorithmPanels.forEach(panel => panel.classList.remove('active'));
            
            // Add active class to clicked button and corresponding panel
            button.classList.add('active');
            const targetPanel = document.getElementById(targetAlgorithm);
            if (targetPanel) {
                targetPanel.classList.add('active');
                
                // Animate panel entrance
                targetPanel.style.opacity = '0';
                targetPanel.style.transform = 'translateY(20px)';
                
                setTimeout(() => {
                    targetPanel.style.transition = 'opacity 0.3s ease, transform 0.3s ease';
                    targetPanel.style.opacity = '1';
                    targetPanel.style.transform = 'translateY(0)';
                }, 50);
            }
        });
    });
}

// Smooth scrolling for anchor links
function initSmoothScrolling() {
    const anchorLinks = document.querySelectorAll('a[href^="#"]');
    
    anchorLinks.forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            
            const targetId = link.getAttribute('href').substring(1);
            const targetElement = document.getElementById(targetId);
            
            if (targetElement) {
                const offsetTop = targetElement.offsetTop - 80; // Account for fixed navbar
                
                window.scrollTo({
                    top: offsetTop,
                    behavior: 'smooth'
                });
            }
        });
    });
}

// Intersection Observer for various animations
function initIntersectionObserver() {
    // Stagger animations for feature cards
    const featureCards = document.querySelectorAll('.feature-card');
    
    const staggerObserver = new IntersectionObserver((entries) => {
        entries.forEach((entry, index) => {
            if (entry.isIntersecting) {
                setTimeout(() => {
                    entry.target.classList.add('animate-fade-in');
                }, index * 100);
                staggerObserver.unobserve(entry.target);
            }
        });
    }, { threshold: 0.1 });
    
    featureCards.forEach(card => {
        staggerObserver.observe(card);
    });
    
    // Doc cards animation
    const docCards = document.querySelectorAll('.doc-card');
    
    const docObserver = new IntersectionObserver((entries) => {
        entries.forEach((entry, index) => {
            if (entry.isIntersecting) {
                setTimeout(() => {
                    entry.target.classList.add('animate-slide-in-up');
                }, index * 150);
                docObserver.unobserve(entry.target);
            }
        });
    }, { threshold: 0.1 });
    
    docCards.forEach(card => {
        docObserver.observe(card);
    });
}

// Parallax effects
function initParallaxEffects() {
    const heroGrid = document.querySelector('.hero-grid');
    const heroGradient = document.querySelector('.hero-gradient');
    
    window.addEventListener('scroll', () => {
        const scrolled = window.pageYOffset;
        const rate = scrolled * -0.5;
        
        if (heroGrid) {
            heroGrid.style.transform = `translateY(${rate}px)`;
        }
        
        if (heroGradient) {
            heroGradient.style.transform = `translateY(${rate * 0.3}px)`;
        }
    });
}

// Typewriter effect for hero section
function initTypewriterEffect() {
    const typewriterElements = document.querySelectorAll('.text-typewriter');
    
    typewriterElements.forEach(element => {
        const text = element.textContent;
        element.textContent = '';
        element.style.borderRight = '2px solid var(--primary)';
        
        let i = 0;
        const typeInterval = setInterval(() => {
            if (i < text.length) {
                element.textContent += text.charAt(i);
                i++;
            } else {
                clearInterval(typeInterval);
                // Blinking cursor effect
                setInterval(() => {
                    element.style.borderRight = element.style.borderRight === 'none' 
                        ? '2px solid var(--primary)' 
                        : 'none';
                }, 500);
            }
        }, 100);
    });
}

// Loading states
function initLoadingStates() {
    // Simulate loading for demo purposes
    const loadingElements = document.querySelectorAll('.loading');
    
    loadingElements.forEach(element => {
        setTimeout(() => {
            element.classList.remove('loading');
        }, 2000);
    });
}

// Showcase section interactions
function initShowcaseInteractions() {
    // Copy to clipboard functionality
    const copyBtn = document.querySelector('.code-action-btn[title="Copy to clipboard"]');
    if (copyBtn) {
        copyBtn.addEventListener('click', () => {
            const codeContent = document.querySelector('.showcase-visual .code-content code');
            if (codeContent) {
                const text = codeContent.textContent;
                navigator.clipboard.writeText(text).then(() => {
                    // Show success feedback
                    const originalHTML = copyBtn.innerHTML;
                    copyBtn.innerHTML = `
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <polyline points="20,6 9,17 4,12"></polyline>
                        </svg>
                    `;
                    copyBtn.style.color = 'var(--secondary)';
                    
                    setTimeout(() => {
                        copyBtn.innerHTML = originalHTML;
                        copyBtn.style.color = '';
                    }, 2000);
                    
                    // Track event
                    trackEvent('showcase_copy_diff', {
                        section: 'showcase',
                        content_type: 'ascii_diff'
                    });
                }).catch(err => {
                    console.error('Failed to copy text: ', err);
                });
            }
        });
    }
    
    // Terminal view toggle
    const terminalBtn = document.querySelector('.code-action-btn[title="View in terminal"]');
    if (terminalBtn) {
        terminalBtn.addEventListener('click', () => {
            const codeContent = document.querySelector('.showcase-visual .code-content');
            if (codeContent) {
                // Toggle terminal styling
                codeContent.classList.toggle('terminal-view');
                
                if (codeContent.classList.contains('terminal-view')) {
                    // Apply terminal colors
                    codeContent.style.background = '#000';
                    codeContent.style.color = '#00ff00';
                    terminalBtn.style.color = 'var(--secondary)';
                } else {
                    // Restore original styling
                    codeContent.style.background = '';
                    codeContent.style.color = '';
                    terminalBtn.style.color = '';
                }
                
                trackEvent('showcase_terminal_toggle', {
                    section: 'showcase',
                    terminal_mode: codeContent.classList.contains('terminal-view')
                });
            }
        });
    }
    
    // Animate showcase features on scroll
    const showcaseFeatures = document.querySelectorAll('.showcase-feature');
    const showcaseObserver = new IntersectionObserver((entries) => {
        entries.forEach((entry, index) => {
            if (entry.isIntersecting) {
                setTimeout(() => {
                    entry.target.style.opacity = '1';
                    entry.target.style.transform = 'translateX(0)';
                    entry.target.style.transition = 'opacity 0.5s ease, transform 0.5s ease';
                }, index * 150);
                showcaseObserver.unobserve(entry.target);
            }
        });
    }, { threshold: 0.1 });
    
    showcaseFeatures.forEach(feature => {
        feature.style.opacity = '0';
        feature.style.transform = 'translateX(-20px)';
        showcaseObserver.observe(feature);
    });
    
    // Animate showcase stats
    const showcaseStats = document.querySelectorAll('.showcase-stats .stat-item');
    const statsObserver = new IntersectionObserver((entries) => {
        entries.forEach((entry, index) => {
            if (entry.isIntersecting) {
                setTimeout(() => {
                    entry.target.style.opacity = '1';
                    entry.target.style.transform = 'translateY(0) scale(1)';
                    entry.target.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
                }, index * 200);
                statsObserver.unobserve(entry.target);
            }
        });
    }, { threshold: 0.1 });
    
    showcaseStats.forEach(stat => {
        stat.style.opacity = '0';
        stat.style.transform = 'translateY(20px) scale(0.9)';
        statsObserver.observe(stat);
    });
    
    // Code demo hover effects
    const codeDemo = document.querySelector('.showcase-visual .code-demo');
    if (codeDemo) {
        codeDemo.addEventListener('mouseenter', () => {
            codeDemo.style.transform = 'scale(1.02)';
            codeDemo.style.transition = 'transform 0.3s ease';
        });
        
        codeDemo.addEventListener('mouseleave', () => {
            codeDemo.style.transform = 'scale(1)';
        });
    }
}

// Utility functions
function debounce(func, wait, immediate) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            timeout = null;
            if (!immediate) func(...args);
        };
        const callNow = immediate && !timeout;
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
        if (callNow) func(...args);
    };
}

function throttle(func, limit) {
    let inThrottle;
    return function() {
        const args = arguments;
        const context = this;
        if (!inThrottle) {
            func.apply(context, args);
            inThrottle = true;
            setTimeout(() => inThrottle = false, limit);
        }
    };
}

// Performance optimizations
function optimizeAnimations() {
    // Reduce animations on low-end devices
    const isLowEndDevice = navigator.hardwareConcurrency <= 2 || 
                          navigator.deviceMemory <= 2 ||
                          /Android|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
    
    if (isLowEndDevice) {
        document.body.classList.add('reduced-animations');
    }
}

// Error handling
window.addEventListener('error', (e) => {
    console.error('JavaScript error:', e.error);
    // Could send error to analytics service
});

// Resize handler
window.addEventListener('resize', debounce(() => {
    // Recalculate positions and sizes if needed
    const event = new CustomEvent('windowResize');
    window.dispatchEvent(event);
}, 250));

// Custom events
window.addEventListener('windowResize', () => {
    // Handle responsive adjustments
    const isMobile = window.innerWidth <= 768;
    document.body.classList.toggle('mobile', isMobile);
});

// Initialize performance optimizations
optimizeAnimations();

// Preload critical resources
function preloadResources() {
    const criticalImages = [
        'images/og-image.png',
        'images/apple-touch-icon.png'
    ];
    
    criticalImages.forEach(src => {
        const link = document.createElement('link');
        link.rel = 'preload';
        link.as = 'image';
        link.href = src;
        document.head.appendChild(link);
    });
}

// Call preload on load
window.addEventListener('load', preloadResources);

// Service Worker registration (if available)
if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
        navigator.serviceWorker.register('/sw.js')
            .then(registration => {
                console.log('SW registered: ', registration);
            })
            .catch(registrationError => {
                console.log('SW registration failed: ', registrationError);
            });
    });
}

// Analytics (placeholder)
function trackEvent(eventName, properties = {}) {
    // Placeholder for analytics tracking
    console.log('Event tracked:', eventName, properties);
    
    // Example: Google Analytics 4
    // gtag('event', eventName, properties);
    
    // Example: Custom analytics
    // analytics.track(eventName, properties);
}

// Track page interactions
document.addEventListener('click', (e) => {
    const target = e.target.closest('a, button');
    if (target) {
        const elementType = target.tagName.toLowerCase();
        const elementText = target.textContent.trim();
        const elementHref = target.href || '';
        
        trackEvent('element_click', {
            element_type: elementType,
            element_text: elementText,
            element_href: elementHref
        });
    }
});

// Export functions for use in other modules
window.MultiLineDiffSite = {
    trackEvent,
    debounce,
    throttle
}; 