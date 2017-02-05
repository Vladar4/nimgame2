// STRUCTURE

/**
 *  Generate a html code for a header link.
 *
 *  @param name     Link name.
 *
 *  @param link     Target html-file (without extension).
 *
 *  @param disabled If true - the link is disabled.
 *
 *  @return a string of html, containing a link to the @param link.
 */
function headerLink(name, link, disabled) {
    var result = '<span><a '
    if(disabled === true)
        result += 'class="disabled" '
    result += 'href="' + link + '.html">' + name + '</a>';
    return result;
}


/**
 *  Fill the <header> of the current html-file.
 *
 *  @param title    Header title.
 */
function createHeader(title) {
    var header = document.querySelector('header');
    header.innerHTML = '<h1>' + title + '</h1>';
    header.innerHTML += headerLink('INDEX', 'index');
    header.innerHTML += headerLink('TUTORIALS', 'tutorials', true);
    header.innerHTML += headerLink('SNIPPETS', 'snippets', true);
    header.innerHTML += headerLink('DOCS', 'docs');
    header.innerHTML += headerLink('LINKS', 'links');
    header.innerHTML += '<hr/>'
}


/**
 *  Fill the <footer> of the current html-file.
 */
function createFooter() {
    var footer = document.querySelector('footer');
    footer.innerHTML = '<hr/><p>\
        Copyright &copy; 2016-2017 Vladar (Vladimir Arabadzhi)\
        (<a href="mailto:vladar4@gmail.com">e-mail</a>)</p>';
}


var docsList = [
    'assets',
    'audio',
    'bitmapfont',
    'collider',
    'count',
    'draw',
    'emitter',
    'entity',
    'font',
    'graphic',
    'input',
    'nimgame',
    'procgraphic',
    'scene',
    'settings',
    'textgraphic',
    'texturegraphic',
    'tilemap',
    'truetypefont',
    'tween',
    'types',
    'utils',
];


/**
 *  Generate a html code for a <li> with a link inside.
 *
 *  @param dir  Path to the target html file.
 *
 *  @param link Target html-file (without extension).
 *
 *  @return a string of html, containing a link for the @param link file.
 */
function listLink(dir, link) {
    return '<li><a href="' + dir + '/' + link + '.html" target="_blank">' +
        link + '</a></li>';
}


/**
 *  Fill the container with documentation links.
 *
 *  @param obj  The target container.
 *
 *  @param from Starting index of the docList array.
 *
 *  @param to   Limiting index of the docList array.
 */
function fillListColumn(obj, from, to) {
    obj.innerHTML = '<ul>';
    for(var i = from; i < to; i++) {
        obj.innerHTML += listLink('docs', docsList[i]);
    }
    obj.innerHTML += '</ul>';
}


/**
 *  Fill the three-column structure of documentation links.
 *
 *  The html structure should be defined as follows:
 *
 *      <div class="three-columns left"></div>
 *      <div class="three-columns center"></div>
 *      <div class="three-columns right"></div>
 */
function createDocsLinks() {
    var col1 = document.querySelector('.three-columns.left');
    var col2 = document.querySelector('.three-columns.center');
    var col3 = document.querySelector('.three-columns.right');
    var oneThird = Math.round(docsList.length / 3);
    var twoThirds = 2 * oneThird;

    fillListColumn(col1, 0, oneThird);
    fillListColumn(col2, oneThird, twoThirds);
    fillListColumn(col3, twoThirds, docsList.length);
}


// EXECUTE

createHeader('Nimgame 2');
createFooter()

