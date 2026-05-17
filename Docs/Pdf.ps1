<#JavaScript code snippet to print LinkedIn recruiter views on Chrome 
https://www.linkedin.com/analytics/recruiter-views/?timeRange=WvmpSearchFilterTimeRange_LAST_90_DAYS

1. Right-click the page, select Inspect, and open the Console tab.
2.Paste this exact block and press Enter:

(function() {
    const style = document.createElement('style');
    style.innerHTML = `
        html, body, #app-container, main, div, section, article {
            overflow: visible !important;
            height: auto !important;
            max-height: none !important;
            min-height: 0 !important;
        }
    `;
    document.head.appendChild(style);
    window.print();
})();
#>



#region  Adobe to edit PDF
Install-WinGetPackage -Id Adobe.Acrobat.Pro -Verbose

<# Warning if you have Adobe reader installed
Adobe Acrobat
Are you sure you want to uninstall? Keep Acrobat Reader to:
. View, print, comment, and share with ease
. Fill and sign forms anytime
. Access PDFs on the go with 2GB free cloud storage
The app is free to use. No billing or subscription required.

Keep using Acrobat for free   |   Continue
#>
#endregion