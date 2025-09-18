// ==UserScript==
// @name         Google Drive PNG Thumbnail Background Fix
// @namespace    http://tampermonkey.net/
// @version      1.0
// @description  Remove background-image from Google Drive thumbnail wrappers
// @author       snoozed_dev
// @match        https://drive.google.com/*
// @updateURL    https://raw.githubusercontent.com/snoozedDev/dotfiles-win/main/Documents/Userscripts/gdrive-png.user.js
// @downloadURL  https://raw.githubusercontent.com/snoozedDev/dotfiles-win/main/Documents/Userscripts/gdrive-png.user.js
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    // Inject CSS to remove background images from thumbnail wrappers
    const style = document.createElement('style');
    style.textContent = `
        /* Remove background images from thumbnail containers */
        div[role="gridcell"] div {
            background-image: none !important;
        }
    `;
    
    document.head.appendChild(style);
})();
