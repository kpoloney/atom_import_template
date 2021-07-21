# Transform descriptions to AtoM template

This is an R shiny web app to transform SFU Archives descriptions to fit the AtoM import template.

## Usage

Within the application:
* Using the file upload button, select the csv of item- and file- level descriptions.
* Click the download button once your upload is complete to download the modified data.

To use the app locally, it must be run using R with the shiny package installed. Use the function `shiny::runApp("filepath")`. It can also be deployed as a standalone app using the process described in the next section.


## Desktop App

For a step-by-step process for deploying the app as a desktop app, see James Young's guide here: [How to Make a Standalone Desktop Application with Shiny and Electron](https://foretodata.com/how-to-make-a-standalone-desktop-application-with-shiny-and-electron-on-windows/). This process uses a clone of COVAIL's [electron-quick-start repository](https://github.com/COVAIL/electron-quick-start), which also contains more information about using electron to deploy a shiny app.

For this method, you will need Git and [Node.js](https://nodejs.org/en/download/) installed. After cloning the COVAIL repository in Git, run the following in the command line:

``
npm install electron-packager -g
cd electron-quick-start
npm install
``

Copy the files from the atom_import repository into the electron-quick-start folder, replacing the sample app.r file in it. 

For Windows, run `npm run package-win`
For Mac, run `npm run package-mac`

Navigate to the executable file in the "ElectronShinyApp" folder and double-click. If the app does not load, click View -> Force Reload.