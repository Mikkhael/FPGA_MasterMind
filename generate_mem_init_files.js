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
    // ['G', [
    //     `.111`,
    //     `1...`,
    //     `1.11`,
    //     '1..1',
    //     '.111',
    // ]],
];

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

    const line_to_hex = (line) => parseInt(line.split('').map(x => x !== '1' ? '0' : '1').join(''),2).toString(16);

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



    const out_file_content = out_file_content_lines.map((x,i) => `\t${(i * mem_size_chars).toString(16)}\t: ${out_file_content_lines[i]};\r\n`).join('');

    const out_file_data = 
`
-- mem_size_chars_used= ${mem_size_chars_used}
-- mem_size_chars     = ${mem_size_chars}
-- mem_size_word_bits = ${mem_size_word_bits}
-- mem_size_words     = ${mem_size_words}
-- mem_size_bits      = ${mem_size_bits}

-- FONT offsets
${font_help}

WIDTH = ${mem_size_word_bits};
DEPTH = ${mem_size_words};
ADDRESS_RADIX = HEX;
DATA_RADIX = HEX;

CONTENT BEGIN
${out_file_content.toUpperCase()}
END;

`;

    return out_file_data;
}

function write(data){
    const filename = process.argv[2] || 'font_mem_init.mif';
    fs.writeFileSync(filename, data);
}

if(validate()){
    const data = generate();
    write(data);
}
