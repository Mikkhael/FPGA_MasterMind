// node generate_mem_init_files.js

const MEM_INIT_FILENAME = 'font_mem_init.mif';
const PARAMS_FILENAME = 'generated_params.vh';

const fs = require('fs');

// DATA

const WIDTH = 4;
const HEIGHT = 5;


const FONT_DATA = [
    ['0', [
        `1111`,
        `1..1`,
        `1..1`,
        '1..1',
        '1111',
    ]],
    ['1', [
        `.11.`,
        `1.1.`,
        `..1.`,
        '..1.',
        '1111',
    ]],
    ['2', [
        `.11.`,
        `1..1`,
        '..1.',
        '.1..',
        '1111',
    ]],
    ['3', [
        `111.`,
        `...1`,
        `.111`,
        '...1',
        '111.',
    ]],
    ['4', [
        `1..1`,
        `1..1`,
        `.11.`,
        '...1',
        '...1',
    ]],
    ['5', [
        `1111`,
        `1...`,
        `111.`,
        '...1',
        '111.',
    ]],
    ['6', [
        `.111`,
        `1...`,
        `111.`,
        '1..1',
        '.11.',
    ]],
    ['7', [
        `1111`,
        `...1`,
        `..1.`,
        '.1..',
        '1...',
    ]],
    ['8', [
        `1111`,
        `1..1`,
        '1111',
        '1..1',
        '1111',
    ]],
    ['9', [
        `1111`,
        `1..1`,
        `.111`,
        '...1',
        '111.',
    ]],
    ['A', [
        `.11.`,
        `1..1`,
        `1111`,
        '1..1',
        '1..1',
    ]],
    ['B', [
        `111.`,
        `1..1`,
        '111.',
        '1..1',
        '111.',
    ]],
    ['C', [
        `.111`,
        `1...`,
        `1...`,
        '1...',
        '.111',
    ]],
    ['D', [
        `111.`,
        `1..1`,
        '1..1',
        '1..1',
        '111.',
    ]],
    ['E', [
        `1111`,
        `1...`,
        '111.',
        '1...',
        '1111',
    ]],
    ['F', [
        `1111`,
        `1...`,
        `111.`,
        '1...',
        '1...',
    ]],
    ['G', [
        `.111`,
        `1...`,
        `1.11`,
        '1..1',
        '.111',
    ]],
    ['H', [
        `1..1`,
        `1..1`,
        `1111`,
        '1..1',
        '1..1',
    ]],
    ['I', [
        `1111`,
        `..1.`,
        `..1.`,
        '..1.',
        '1111',
    ]],
    ['J', [
        `1111`,
        `...1`,
        `...1`,
        '1..1',
        '.11.',
    ]],
    ['K', [
        `1..1`,
        `1.1.`,
        `11..`,
        '1.1.',
        '1..1',
    ]],
    ['L', [
        `1...`,
        `1...`,
        `1...`,
        '1...',
        '1111',
    ]],
    ['M', [
        `1..1`,
        `1111`,
        `1..1`,
        '1..1',
        '1..1',
    ]],
    ['N', [
        `1..1`,
        `11.1`,
        `1.11`,
        '1..1',
        '1..1',
    ]],
    ['O', [
        `.11.`,
        `1..1`,
        `1..1`,
        '1..1',
        '.11.',
    ]],
    ['P', [
        `111.`,
        `1..1`,
        `111.`,
        '1...',
        '1...',
    ]],
    ['Q', [
        `.11.`,
        `1..1`,
        `11.1`,
        '1.11',
        '.111',
    ]],
    ['R', [
        `111.`,
        `1..1`,
        `111.`,
        '1.1.',
        '1..1',
    ]],
    ['S', [
        `.111`,
        `1...`,
        `.11.`,
        '...1',
        '111.',
    ]],
    ['T', [
        `1111`,
        `..1.`,
        `..1.`,
        '..1.',
        '..1.',
    ]],
    ['U', [
        `1..1`,
        `1..1`,
        `1..1`,
        '1..1',
        '.11.',
    ]],
    ['V', [
        `1..1`,
        `1..1`,
        `1..1`,
        '.1.1',
        '..1.',
    ]],
    ['W', [
        `1..1`,
        `1..1`,
        `1..1`,
        '1111',
        '.11.',
    ]],
    ['X', [
        `1..1`,
        `1..1`,
        `.11.`,
        '1..1',
        '1..1',
    ]],
    ['Y', [
        `1..1`,
        `1..1`,
        `.11.`,
        '..1.',
        '..1.',
    ]],
    ['Z', [
        `1111`,
        `..11`,
        `.11.`,
        '11..',
        '1111',
    ]],
    [' ', [
        `....`,
        `....`,
        `....`,
        '....',
        '....',
    ]],
    ['QMark', [
        `111.`,
        `...1`,
        `.11.`,
        '....',
        '.1..',
    ]],
    ['Hash', [
        `.1.1`,
        `1111`,
        `.11.`,
        '1111',
        '1.1.',
    ]],
    ['ArrowR', [
        `11..`,
        `.11.`,
        `..11`,
        '.11.',
        '11..',
    ]],
    ['ArrowL', [
        `..11`,
        `.11.`,
        `11..`,
        '.11.',
        '..11',
    ]],
];


const LONG_SPRITES_DATA = [
    ['MM', [
        `11....11`,
        `1.1..1.1`,
        `1..11..1`,
        '1......1',
        '11....11',
    ]],
    ['Mind', [
        `1...1.1........1`,
        `11.11..........1`,
        `1.1.1.1.111..111`,
        `1...1.1.1..1.1.1`,
        `1...1.1.1..1.111`,
    ]],
];

const S = str => str.split('');
const STRINGS = [
    ['TITLE', ['MM', ...S('ASTER'), 'Mind'], true],
    ['PLAY VS COMPUTER'],
    ['PLAY VS HUMAN'],
    ['OPTIONS'],
    ['HIGHSCORES'],

    ['GUESS'],
    ['EXIT'],

    ['BACK', ['ArrowL', 'ArrowL', ...S(' BACK '), 'ArrowL', 'ArrowL']],

    ['PIN COLORS'],
    ['PINS COUNT'],
    ['GUESSES'],
    ['PIXEL WIDTH'],
    ['PIXEL HEIGHT'],
    ['PALETTE'],
];

function main(){
    

// VALIDATE

for(let [name, data] of FONT_DATA){
    if(data.length != HEIGHT){
        console.error('INVALID FONT HEIGHT', name, data.length, data);
        return false;
    }
    for(let row of data){
        if(row.length != WIDTH){
            console.error('INVALID FONT WIDTH', name, row.length, row);
            return false;
        }
    }
}

for(let i = 0; i < LONG_SPRITES_DATA.length; i++){
    let [name, data] = LONG_SPRITES_DATA[i];
    if(data.length != HEIGHT){
        console.error('INVALID FONT HEIGHT', name, data.length, data);
        return false;
    }
    const full_width = data[0].length;
    if((full_width % WIDTH) !== 0){
        console.error('INVALID FONT WIDTH', name, full_width, data);
        return false;
    }
    for(let row of data){
        if(row.length != full_width){
            console.error('INVALID FONT WIDTH', name, row.length, row);
            return false;
        }
    }
}



// GENERATE LOOKUPS

const FONT_COUNT = FONT_DATA.length;
const LONG_SPRITES_COUNT = LONG_SPRITES_DATA.length;

function convert_to_lookup_object(arr){
    let res = {};
    let acc = 0;
    for(let i=0; i<arr.length; i++){
        const len = arr[i][1][0].length / WIDTH;
        res[arr[i][0]] = {off: acc, data: arr[1], len};
        arr[i][2] = acc;
        arr[i][3] = len;
        acc += len;
    }
    return [res, acc];
}

const [FONT_LOOKUP, FONT_ROW_WORDS_COUNT] = convert_to_lookup_object(FONT_DATA);
const [LONG_SPRITES_LOOKUP, LONG_SPRITES_ROW_WORDS_COUNT] = convert_to_lookup_object(LONG_SPRITES_DATA);

const ALL_CHARS_DATA = [...FONT_DATA, ...LONG_SPRITES_DATA];

// GENERATE MEM INIT

function split_by_width(str){
    let splits = Math.floor(str.length / WIDTH);
    let res = [];
    for(let i=0; i<splits; i++){
        res.push(str.slice(i * WIDTH, (i+1) * WIDTH));
    }
    return res;
}
function get_min_width(num){
    if(num < 0) num = 0;
    const bin = num.toString(2);
    return bin.length;
}
function next_power(num) {
    return 1 << (get_min_width(num-1));
}
const to_word_str = (line) => line.split('').map(x => x !== '1' ? '0' : '1').join('');

const memory_row_words_count_used = FONT_ROW_WORDS_COUNT + LONG_SPRITES_ROW_WORDS_COUNT;
const memory_row_words_count = next_power(memory_row_words_count_used);

const memory_words_count_used = memory_row_words_count * HEIGHT;
const memory_words_count = next_power(memory_words_count_used);
const memory_addr_width = get_min_width(memory_words_count-1);

let mem_file_content_lines = [];
for(let i = 0; i<HEIGHT; i++){
    mem_file_content_lines[i] = ALL_CHARS_DATA.map(
        char => split_by_width(char[1][i]).map(
            word => to_word_str(word)
        ).join(' ')
    );
    mem_file_content_lines[i].push(Array(memory_row_words_count - memory_row_words_count_used).fill('0000').join(' '));
    mem_file_content_lines[i] = mem_file_content_lines[i].join(' ');
}

const mem_file_content = mem_file_content_lines.map(
    (x,i) => `\t${(i * memory_row_words_count).toString(16)}\t: ${mem_file_content_lines[i]};\r\n`
).join('');

const mem_file_data = 
`
-- font_chars_count         = ${FONT_COUNT}
-- long_sprites_count       = ${LONG_SPRITES_COUNT}
-- long_sprites_chars_count = ${LONG_SPRITES_ROW_WORDS_COUNT}
-- words_per_row_used       = ${memory_row_words_count_used}
-- words_per_row_total      = ${memory_row_words_count} (2^${get_min_width(memory_row_words_count-1)})
-- words_used               = ${memory_words_count_used}
-- words_total              = ${memory_words_count} (2^${memory_addr_width-1})
-- bits_total               = ${memory_words_count * WIDTH}

WIDTH = ${WIDTH};
DEPTH = ${memory_words_count};
ADDRESS_RADIX = HEX;
DATA_RADIX = BIN;

CONTENT BEGIN
${mem_file_content.toUpperCase()}
END;

`;


// STRINGS

function string_to_inds(string){
    let [name, labels] = string;
    if(labels === undefined){
        labels = name;
    }
    if(typeof(labels) === "string"){
        labels = labels.split('');
    }
    let inds = labels.map(label => {
        if(FONT_LOOKUP[label]){
            return [FONT_LOOKUP[label].off];
        }
        if(LONG_SPRITES_LOOKUP[label]){
            let spr = LONG_SPRITES_LOOKUP[label];
            let res = [];
            for(let i=0; i<spr.len; i++){
                res.push(spr.off + i + FONT_COUNT);
            }
            return res;
        }
        console.error('NOT FOUND STRING LABEL: ', label);
        return [0];
    });

    return inds.flat();
}
function string_to_mask(string){
    let [name, labels] = string;
    if(labels === undefined){
        labels = name;
    }
    if(typeof(labels) === "string"){
        labels = labels.split('');
    }
    let mask = labels.map(label => {
        if(FONT_LOOKUP[label]){
            return [0];
        }
        if(LONG_SPRITES_LOOKUP[label]){
            let spr = LONG_SPRITES_LOOKUP[label];
            let res = [];
            for(let i=0; i<spr.len-1; i++){
                res.push(1);
            }
            return [...Array(spr.len-1).fill(1), 0];
        }
        console.error('NOT FOUND STRING LABEL: ', label);
        return [0];
    });

    return mask.flat();
}

const STRINGS_INDS = STRINGS.map(string => {return {name: string[0].replace(/ /g, ''), inds: string_to_inds(string), mask: string_to_mask(string)} });

/// PARAMETERS

const W = (val, w) => `${w === undefined ? get_min_width(val) : w}'d${val}`;

const simple_params = [
    ['ADDR_W', memory_addr_width],
    ['FONT_H', HEIGHT],
    ['FONT_W', WIDTH],
    ['FONT_CHARS', FONT_COUNT],
    ['FONT_LINEOFF', memory_row_words_count],
    ['FONT_LINESHIFT', get_min_width(memory_row_words_count-1)],
    ...FONT_DATA.map(([name, data, off, len]) => [`CHAR_${name}`, off]),
    ...LONG_SPRITES_DATA.map(([name, data, off, len]) => [`LSPRITE_${name}_LEN`, len]),
    ...LONG_SPRITES_DATA.map(([name, data, off, len]) => [`LSPRITE_${name}`, off + FONT_COUNT]),
    ...STRINGS_INDS.map(({name, inds}) => [`STR_${name}_LEN`, inds.length]),
].map(([name, val, w]) => `parameter ${name} = ${W(val, w)};\r\n`).join('');

const strings_params      = STRINGS_INDS.map(({name, inds}) => `parameter logic [${memory_addr_width-1}:0] STR_${name} [${inds.length}] = '{${inds.join(',')}};\r\n`).join('');
const strings_mask_params = STRINGS_INDS.map(({name, mask}) => `parameter logic STR_MASK_${name} [${mask.length}] = '{${mask.join(',')}};\r\n`).join('');
const params_file_data = simple_params + strings_params + strings_mask_params;

/// WRITE


fs.writeFileSync(MEM_INIT_FILENAME, mem_file_data);
fs.writeFileSync(PARAMS_FILENAME, params_file_data);

}

main();
