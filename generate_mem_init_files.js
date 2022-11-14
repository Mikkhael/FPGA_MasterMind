// Usage:
// node generate_mem_init_files.js (output_file)

const fs = require('fs');

// DATA

const FONT_WIDTH = 4;
const FONT_HEIGHT = 5;


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
    ['M1', [
        `11..`,
        `1.1.`,
        `1..1`,
        '1...',
        '1...',
    ]],
    ['M2', [
        `..11`,
        `.1.1`,
        `1..1`,
        '...1',
        '...1',
    ]],
];


// STRINGS

const STRINGS = [
    ['TITLE',  ['M1', 'M2', '.ASTER', 'M1', 'M2', '.IND']],
    ['OPTS', 'OPTIONS'],
    ['TEST'],
];


function generate_strings_inds(){
    const font = {};
    for(let i=0; i<FONT_DATA.length; i++){
        font[FONT_DATA[i][0]] = i;
    }

    const res = {};

    for(let [name, value] of STRINGS){
        if(value === undefined){
            value = name;
        }
        if(typeof(value) == 'string'){
            value = value.split('');
        }
        let chars = [];
        for(let i=0; i<value.length; i++){
            if(value[i].length > 0 && value[i][0] == '.'){
                chars = [...chars, ...value[i].slice(1).split('')];
            }else{
                chars.push(value[i]);
            }
        }
        let inds = [];
        for(let i=0; i<chars.length; i++){
            let ind = font[chars[i]];
            if(ind === undefined){
                console.error("ERROR WITH STRINGS", name, value, chars, i);
            }
            inds.push(ind);
        }

        res[name] = inds;
    }
    return res;
}
let W = 0;
function generate_string_parameters(){
    const strs = generate_strings_inds(W);


    return Object.entries(strs).map(str => 
        `parameter STR_${str[0]}_LEN = ${str[1].length};\r\n` +
        `parameter logic [${W-1}:0] STR_${str[0]} [${str[1].length}] = '{${str[1].join(',')}};\r\n`
    ).join('');
}


// CALCULATION

function validate(){
    for(let [char_name, char_data] of FONT_DATA){
        if(char_data.length !== FONT_HEIGHT){
            console.log('Invalid font height for char: ', char_name);
            return false;
        }
        for(let char_line_data of char_data){
            if(char_line_data.length !== FONT_WIDTH){
                console.log('Invalid font width for char: ', char_name);
                return false;
            }
        }
    }
    return true;
}

function generate(){

    const mem_size_chars_used = FONT_DATA.length;

    const font_help = FONT_DATA.map((x,i) => `--  \t${x[0]}\t: ${i.toString(16).toUpperCase()}\r\n`).join('');

    // const line_to_hex = (line) => parseInt(line.split('').map(x => x !== '1' ? '0' : '1').join(''),2).toString(16);
    const line_to_hex = (line) => line.split('').map(x => x !== '1' ? '0' : '1').join('');

    let out_file_content_lines = [];
    for(let i = 0; i<FONT_HEIGHT; i++){
        out_file_content_lines[i] = FONT_DATA.map(x => line_to_hex(x[1][i])).join(' ');
    }

    let mem_size_chars = FONT_DATA.length;
    if(!mem_size_chars.toString(2).match(/^10*$/)){
        mem_size_chars = (1 << (mem_size_chars.toString(2).length));
    }

    const mem_size_word_bits = FONT_WIDTH;
    const mem_size_words = FONT_HEIGHT * mem_size_chars;
    const mem_size_bits =  FONT_WIDTH * mem_size_words;

    W = mem_size_chars.toString(2).length-1;

    const out_file_content = out_file_content_lines.map((x,i) => `\t${(i * mem_size_chars).toString(16)}\t: ${out_file_content_lines[i]};\r\n`).join('');

    const out_file_data = 
`
-- mem_size_chars_used= ${mem_size_chars_used}
-- mem_size_chars     = ${mem_size_chars} (2^${W})
-- mem_size_word_bits = ${mem_size_word_bits}
-- mem_size_words     = ${mem_size_words}
-- mem_size_bits      = ${mem_size_bits}

-- FONT offsets
${font_help}

WIDTH = ${mem_size_word_bits};
DEPTH = ${mem_size_words};
ADDRESS_RADIX = HEX;
DATA_RADIX = BIN;

CONTENT BEGIN
${out_file_content.toUpperCase()}
END;

`;

    return out_file_data;
}

function write(data, params_data){
    const filename = process.argv[2] || 'font_mem_init.mif';
    fs.writeFileSync(filename, data);
    fs.writeFileSync('strings.vh', params_data);

}

if(validate()){
    const data = generate();
    const params_data = generate_string_parameters();
    write(data, params_data);
}
