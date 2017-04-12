// STRUCTURE


/**
 *  Create favicon link tag.
 */
function createFavicon() {
    var icon = document.createElement('link');
    icon.rel = 'shortcut icon';
    icon.href = 'favicon.ico';
    icon.type = "image/x-icon";
    document.querySelector('head').appendChild(icon);
}


/**
 *  Create a header link object.
 *
 *  @param name     Link name (without extension).
 *
 *  @param disabled If true - the link is disabled.
 *
 *  @return an object with a link to the @param link.
 */
function headerLink(name, disabled) {
    var a = document.createElement('a');
    if(disabled)
        a.classList.add('disabled');
    a.href = name + '.html';
    a.classList.add('menu');
    a.innerHTML = name.toUpperCase();
    var result = document.createElement('span');
    result.appendChild(a);
    return result;
}


/**
 *  Fill the <header> of the current html-file.
 *
 *  @param title    Header title.
 *
 *  @param logo     Path to the logo image (without extension).
 */
function createHeader(title, logo) {
    var img = document.createElement('img');
    img.src = logo + '.png';

    var logoLink = document.createElement('a');
    logoLink.href = 'index.html';
    logoLink.target = '_self';
    logoLink.appendChild(img);

    var logo = document.createElement('div');
    logo.classList.add('logo');
    logo.appendChild(logoLink);

    var headerTitle = document.createElement('h1');
    headerTitle.innerHTML = title;

    var headerLinks = [
        headerLink('index'),
        headerLink('demos'),
        headerLink('tutorials', true),
        headerLink('snippets'),
        headerLink('docs'),
        headerLink('links'),
    ];

    var menu = document.createElement('div');
    for(var i = 0; i < headerLinks.length; i++) {
        menu.appendChild(headerLinks[i]);
    }

    var titleDiv = document.createElement('div');
    titleDiv.appendChild(headerTitle);
    titleDiv.appendChild(menu);

    var logoR = document.createElement('div');
    logoR.classList.add('logo');

    var headerDiv = document.createElement('div');
    headerDiv.appendChild(logo);
    headerDiv.appendChild(titleDiv);
    headerDiv.appendChild(logoR);

    var header = document.querySelector('header');
    header.appendChild(headerDiv);
    header.appendChild(document.createElement('hr'));
}


/**
 *  Fill the <footer> of the current html-file.
 */
function createFooter() {
    var text = document.createElement('p');
    text.innerHTML = '\
        Copyright &copy; 2016-2017 Vladar (Vladimir Arabadzhi)\
        (<a href="mailto:vladar4@gmail.com">e-mail</a>)';

    var footer = document.querySelector('footer');
    footer.appendChild(document.createElement('hr'));
    footer.appendChild(text);
}

/**
 *  Fill <aside> with @param cname snippet class links.
 */
function createClassList(cname) {
    document.querySelector('body').id = 'top';
    var list = document.querySelectorAll(cname);

    for(var i = 0; i < list.length; i++) {
        var title = list[i].childNodes[0];
        title.style.display = 'inline';

        var link = document.createElement('a');
        link.href = '#' + list[i].id;
        link.innerHTML = title.innerHTML;

        var backLink = document.createElement('a');
        backLink.href = '#top';
        backLink.innerHTML = '&#8632;'; // back arrow

        var spacing = document.createElement('span');
        spacing.innerHTML = '&nbsp';

        var titleLink = document.createElement('a');
        titleLink.href = '#' + list[i].id;

        var titleLine = document.createElement('div');
        list[i].insertBefore(titleLine, title);
        titleLine.appendChild(backLink);
        titleLine.appendChild(spacing);
        titleLine.appendChild(titleLink);
        titleLink.appendChild(title);

        // aside
        var line = document.createElement('p');
        line.appendChild(link);
        var aside = document.querySelector('aside');
        aside.style.display = 'flex';
        aside.appendChild(line);
    }
}


function createSnippetsList() {
    createClassList('.snippet')
}

function createSectionsList() {
    createClassList('.section')
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
    'gui/button',
    'gui/textinput',
    'gui/widget',
    'input',
    'mosaic',
    'nimgame',
    'procgraphic',
    'scene',
    'settings',
    'textfield',
    'textgraphic',
    'texturegraphic',
    'tilemap',
    'truetypefont',
    'tween',
    'types',
    'utils',
];


/**
 *  Create a <li> element with a link inside.
 *
 *  @param dir  Path to the target html file.
 *
 *  @param link Target html-file (without extension).
 *
 *  @return a <li> element, containing a link for the @param link file.
 */
function listLink(dir, link) {
    var result = document.createElement('li');
    result.innerHTML = '\
        <a href="' + dir + '/' + link + '.html" target="_blank">' +
        link + '</a>';
    return result;
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
    var list = document.createElement('ul');
    for(var i = from; i < to; i++) {
        list.appendChild(listLink('docs', docsList[i]));
    }
    obj.appendChild(list);
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
    var col1 = document.querySelector('#col1');
    var col2 = document.querySelector('#col2');
    var col3 = document.querySelector('#col3');
    var oneThird = Math.round(docsList.length / 3);
    var twoThirds = 2 * oneThird;

    fillListColumn(col1, 0, oneThird);
    fillListColumn(col2, oneThird, twoThirds);
    fillListColumn(col3, twoThirds, docsList.length);
}


function createRanks() {
    var list = document.querySelectorAll('.rank');
    for(i = 0; i < list.length; i++) {
        var attr_is = list[i].getAttribute('is');
        var attr_of = list[i].getAttribute('of');
        for(n = 0; n < attr_is; n++) {
            var starf = document.createElement('img');
            starf.classList.add('star');
            starf.src = 'images/icons/starf.png';
            list[i].appendChild(starf);
        }
        for(m = 0; m < (attr_of - attr_is); m++) {
            var stare = document.createElement('img');
            stare.classList.add('star');
            stare.src = 'images/icons/stare.png';
            list[i].appendChild(stare);
        }
    }
}


// EXECUTE

createFavicon();
createHeader('Nimgame 2', 'images/icons/logo');
createFooter()

