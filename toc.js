// Populate the sidebar
//
// This is a script, and not included directly in the page, to control the total size of the book.
// The TOC contains an entry for each page, so if each page includes a copy of the TOC,
// the total size of the page becomes O(n**2).
class MDBookSidebarScrollbox extends HTMLElement {
    constructor() {
        super();
    }
    connectedCallback() {
        this.innerHTML = '<ol class="chapter"><li class="chapter-item expanded affix "><a href="index.html">Home</a></li><li class="chapter-item expanded affix "><a href="CHANGELOG.html">Changelog</a></li><li class="chapter-item expanded affix "><li class="spacer"></li><li class="chapter-item expanded "><a href="introduction.html"><strong aria-hidden="true">1.</strong> Introduction</a></li><li><ol class="section"><li class="chapter-item expanded "><a href="introduction/artifact-reuse.html"><strong aria-hidden="true">1.1.</strong> Artifact reuse</a></li><li class="chapter-item expanded "><a href="introduction/sequential-builds.html"><strong aria-hidden="true">1.2.</strong> Sequential builds</a></li></ol></li><li class="chapter-item expanded "><a href="getting-started.html"><strong aria-hidden="true">2.</strong> Getting started</a></li><li><ol class="section"><li class="chapter-item expanded "><a href="examples/quick-start.html"><strong aria-hidden="true">2.1.</strong> Quick start</a></li><li class="chapter-item expanded "><a href="examples/quick-start-simple.html"><strong aria-hidden="true">2.2.</strong> Quick start (simple)</a></li><li class="chapter-item expanded "><a href="examples/quick-start-workspace.html"><strong aria-hidden="true">2.3.</strong> Quick start (workspace)</a></li><li class="chapter-item expanded "><a href="examples/custom-toolchain.html"><strong aria-hidden="true">2.4.</strong> Custom toolchain</a></li><li class="chapter-item expanded "><a href="examples/alt-registry.html"><strong aria-hidden="true">2.5.</strong> Alternative registry</a></li><li class="chapter-item expanded "><a href="examples/build-std.html"><strong aria-hidden="true">2.6.</strong> Building standard library crates</a></li><li class="chapter-item expanded "><a href="examples/cross-rust-overlay.html"><strong aria-hidden="true">2.7.</strong> Cross compiling</a></li><li class="chapter-item expanded "><a href="examples/cross-musl.html"><strong aria-hidden="true">2.8.</strong> Cross compiling with musl</a></li><li class="chapter-item expanded "><a href="examples/cross-windows.html"><strong aria-hidden="true">2.9.</strong> Cross compiling to windows</a></li><li class="chapter-item expanded "><a href="examples/trunk.html"><strong aria-hidden="true">2.10.</strong> Building Trunk projects</a></li><li class="chapter-item expanded "><a href="examples/trunk-workspace.html"><strong aria-hidden="true">2.11.</strong> Workspace with Trunk</a></li><li class="chapter-item expanded "><a href="examples/end-to-end-testing.html"><strong aria-hidden="true">2.12.</strong> End-to-End Testing</a></li><li class="chapter-item expanded "><a href="examples/sqlx.html"><strong aria-hidden="true">2.13.</strong> Building with SQLx</a></li></ol></li><li class="chapter-item expanded "><a href="source-filtering.html"><strong aria-hidden="true">3.</strong> Source filtering and filesets</a></li><li class="chapter-item expanded "><a href="local_development.html"><strong aria-hidden="true">4.</strong> Local development</a></li><li class="chapter-item expanded "><a href="custom_cargo_commands.html"><strong aria-hidden="true">5.</strong> Custom cargo commands</a></li><li class="chapter-item expanded "><a href="customizing_builds.html"><strong aria-hidden="true">6.</strong> Customizing builds</a></li><li class="chapter-item expanded "><a href="overriding_derivations.html"><strong aria-hidden="true">7.</strong> Overriding derivations after the fact</a></li><li class="chapter-item expanded "><a href="patching_dependency_sources.html"><strong aria-hidden="true">8.</strong> Patching sources of dependencies</a></li><li class="chapter-item expanded affix "><li class="spacer"></li><li class="chapter-item expanded "><a href="API.html"><strong aria-hidden="true">9.</strong> API Reference</a></li><li class="chapter-item expanded affix "><li class="spacer"></li><li class="chapter-item expanded "><a href="faq/faq.html"><strong aria-hidden="true">10.</strong> Troubleshooting/FAQ</a></li><li><ol class="section"><li class="chapter-item expanded "><a href="faq/custom-nixpkgs.html"><strong aria-hidden="true">10.1.</strong> Customizing nixpkgs and other inputs</a></li><li class="chapter-item expanded "><a href="faq/ifd-error.html"><strong aria-hidden="true">10.2.</strong> IFD (import from derivation) errors</a></li><li class="chapter-item expanded "><a href="faq/constant-rebuilds.html"><strong aria-hidden="true">10.3.</strong> Constantly rebuilding from scratch</a></li><li class="chapter-item expanded "><a href="faq/rebuilds-with-different-toolchains.html"><strong aria-hidden="true">10.4.</strong> Crates being rebuilt when using different toolchains</a></li><li class="chapter-item expanded "><a href="faq/rebuilds-with-proc-macros.html"><strong aria-hidden="true">10.5.</strong> Constantly rebuilding proc-macro dependencies dev mode</a></li><li class="chapter-item expanded "><a href="faq/rebuilds-pyo3.html"><strong aria-hidden="true">10.6.</strong> Constantly rebuilding pyo3</a></li><li class="chapter-item expanded "><a href="faq/rebuilds-bindgen.html"><strong aria-hidden="true">10.7.</strong> Constantly rebuilding bindgen</a></li><li class="chapter-item expanded "><a href="faq/no-cargo-lock.html"><strong aria-hidden="true">10.8.</strong> Building upstream cargo crate with no Cargo.lock</a></li><li class="chapter-item expanded "><a href="faq/patching-cargo-lock.html"><strong aria-hidden="true">10.9.</strong> Patching Cargo.lock during build</a></li><li class="chapter-item expanded "><a href="faq/build-workspace-subset.html"><strong aria-hidden="true">10.10.</strong> Building a subset of a workspace</a></li><li class="chapter-item expanded "><a href="faq/building-with-non-rust-includes.html"><strong aria-hidden="true">10.11.</strong> Trouble building when using include_str! (or including other non-rust files)</a></li><li class="chapter-item expanded "><a href="faq/sandbox-unfriendly-build-scripts.html"><strong aria-hidden="true">10.12.</strong> Dealing with sandbox-unfriendly build scripts</a></li><li class="chapter-item expanded "><a href="faq/workspace-not-at-source-root.html"><strong aria-hidden="true">10.13.</strong> Cargo.toml is not at the source root</a></li><li class="chapter-item expanded "><a href="faq/invalid-metadata-files-for-crate.html"><strong aria-hidden="true">10.14.</strong> Found invalid metadata files for crate error</a></li><li class="chapter-item expanded "><a href="faq/git-dep-cannot-find-relative-path.html"><strong aria-hidden="true">10.15.</strong> A git dependency fails to find a file by a relative path</a></li><li class="chapter-item expanded "><a href="faq/control-when-hooks-run.html"><strong aria-hidden="true">10.16.</strong> Controlling whether or not hooks run during buildDepsOnly</a></li></ol></li><li class="chapter-item expanded "><li class="spacer"></li><li class="chapter-item expanded "><a href="advanced/advanced.html"><strong aria-hidden="true">11.</strong> Advanced Techniques</a></li><li><ol class="section"><li class="chapter-item expanded "><a href="advanced/overriding-function-behavior.html"><strong aria-hidden="true">11.1.</strong> Overriding function behavior</a></li></ol></li></ol>';
        // Set the current, active page, and reveal it if it's hidden
        let current_page = document.location.href.toString().split("#")[0];
        if (current_page.endsWith("/")) {
            current_page += "index.html";
        }
        var links = Array.prototype.slice.call(this.querySelectorAll("a"));
        var l = links.length;
        for (var i = 0; i < l; ++i) {
            var link = links[i];
            var href = link.getAttribute("href");
            if (href && !href.startsWith("#") && !/^(?:[a-z+]+:)?\/\//.test(href)) {
                link.href = path_to_root + href;
            }
            // The "index" page is supposed to alias the first chapter in the book.
            if (link.href === current_page || (i === 0 && path_to_root === "" && current_page.endsWith("/index.html"))) {
                link.classList.add("active");
                var parent = link.parentElement;
                if (parent && parent.classList.contains("chapter-item")) {
                    parent.classList.add("expanded");
                }
                while (parent) {
                    if (parent.tagName === "LI" && parent.previousElementSibling) {
                        if (parent.previousElementSibling.classList.contains("chapter-item")) {
                            parent.previousElementSibling.classList.add("expanded");
                        }
                    }
                    parent = parent.parentElement;
                }
            }
        }
        // Track and set sidebar scroll position
        this.addEventListener('click', function(e) {
            if (e.target.tagName === 'A') {
                sessionStorage.setItem('sidebar-scroll', this.scrollTop);
            }
        }, { passive: true });
        var sidebarScrollTop = sessionStorage.getItem('sidebar-scroll');
        sessionStorage.removeItem('sidebar-scroll');
        if (sidebarScrollTop) {
            // preserve sidebar scroll position when navigating via links within sidebar
            this.scrollTop = sidebarScrollTop;
        } else {
            // scroll sidebar to current active section when navigating via "next/previous chapter" buttons
            var activeSection = document.querySelector('#sidebar .active');
            if (activeSection) {
                activeSection.scrollIntoView({ block: 'center' });
            }
        }
        // Toggle buttons
        var sidebarAnchorToggles = document.querySelectorAll('#sidebar a.toggle');
        function toggleSection(ev) {
            ev.currentTarget.parentElement.classList.toggle('expanded');
        }
        Array.from(sidebarAnchorToggles).forEach(function (el) {
            el.addEventListener('click', toggleSection);
        });
    }
}
window.customElements.define("mdbook-sidebar-scrollbox", MDBookSidebarScrollbox);
