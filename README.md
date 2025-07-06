
<h1 align="center">
  SFwes - WIP
  <br>
</h1>

<h4 align="center">A Neovim plugin to support Salesforce development.

<p align="center">
  <a href="#key-features">Key Features</a> •
  <a href="#how-to-use">How To Use</a>
</p>

## Key Features

* Command to deploy your currently open buffer to your project's default org
* Command to refresh the metadata in your currently open buffer from your project's default org
* Command to create a new apex or trigger class, or lwc

### Running tests

* Command to execute apex tests, which can be specified by all tests in current buffer, or a single test with the name on your currently highlighted line
* Decorates the leftmost column with a play button to signify that the plugin has detected runnable apex tests in your buffer
* Opens a test panel to show currently running tests, and their results
      
## How To Use

To install this application, ensure that you have Neovim and Lazy installed. Then, clone this repo into your Neovim plugin directory.
