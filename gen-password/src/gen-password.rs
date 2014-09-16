#![feature(macro_rules)]
extern crate getopts;
use getopts::{optopt,optflag,getopts,OptGroup};

use std::io::{BufferedReader,File};
use std::os;
use std::rand::{sample,task_rng};


macro_rules! random_char {
    () => {
        random_char("!$%^&*#(){}[];:<>?/|+-")
    };
    ($chars:expr) => {
        random_char($chars)
    }
}


macro_rules! random_password {
    () => {
        random_password(16)
    };
    ($len:expr) => {
        random_password($len)
    }
}


fn random_char(chars: &str) -> char {
    let mut rng = task_rng();
    sample(&mut rng, chars.chars(), 1)[0]
}


fn random_word(words: &Vec<String>) -> String {
    let mut rng = task_rng();
    sample(&mut rng, words.iter(), 1)[0].as_slice().trim().to_string()
}


fn random_password(len: uint) -> String {
    let chars: &str = "abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789\
        !$%^&*#(){}[];:<>?/|+-";
    let mut pass = String::new();
    for _ in range(0u, len) {
        pass.push_char(random_char!(chars));
    }
    pass
}


#[test]
fn test_random_password_length() {
    let pass5 = random_password(5);
    let pass10 = random_password(10);
    assert!(pass5.len() == 5);
    assert!(pass10.len() == 10);
}


#[test]
fn test_random_password_uniqueness() {
    let pass1 = random_password(16);
    let pass2 = random_password(16);
    assert!(pass1 != pass2);
}


fn dictwords_password() -> String {
    let mut pass = String::new();
    let path = Path::new("/usr/share/dict/words");
    let mut file = BufferedReader::new(File::open(&path));
    let lines: Vec<String> = file.lines().map(
        |x| x.unwrap().replace("'s", "")
    ).filter(
        |x| x.len() > 5 && x.len() <= 10
    ).collect();
    let (tx, rx) = channel();
    for _ in range(0u, 2) {
        let tx = tx.clone();
        let lines = lines.clone();
        spawn(proc() {
            tx.send(random_word(&lines));
        });
    }
    pass.push_str(rx.recv().as_slice());
    pass.push_char(random_char!());
    for _ in range(0u, 2) {
        pass.push_char(random_char!("0123456789"));
    }
    pass.push_str(rx.recv().as_slice());
    pass
}


#[test]
fn test_dictwords_password_uniqueness() {
    let pass1 = dictwords_password();
    let pass2 = dictwords_password();
    assert!(pass1 != pass2);
}


fn print_usage(program: &str, _opts: &[OptGroup]) {
    println!("Usage: {} [options]", program);
    println!("-m --mode [random|] \t Password generation mode");
    println!("    random    - Generate a random string (default length is 16)");
    println!("    dictwords - Generate a password of the form ");
    println!("                <word><symbol><num><num><word>");
    println!("-l --length LENGTH \t Password length (for random generator)");
    println!("-h --help \t Usage");
}


fn main() {
    let args: Vec<String> = os::args().iter().map(
        |x| x.to_string()
    ).collect();

    let program = args[0].clone();

    let opts = [
        optopt("m", "mode", "mode", ""),
        optopt("l", "length", "password length for random generator", "LENGTH"),
        optflag("h", "help", "print this help menu")
    ];
    let matches = match getopts(args.tail(), opts) {
        Ok(m) => { m }
        Err(f) => { fail!("{}", f) }
    };
    if matches.opt_present("h") {
        print_usage(program.as_slice(), opts);
        return;
    }
    match matches.opt_str("m").unwrap_or(String::from_str("random")).as_slice() {
        "random" => {
            let len_str = match matches.opt_default("l", "16") {
                Some(ref s) => { s.to_string() },
                None => String::from_str("16"),
            };
            let len = match from_str::<uint>(len_str.as_slice()) {
                Some(n) => { n },
                None => { 
                    println!("{} is not a valid length.", len_str);
                    return;
                }
            };
    
            let pass = random_password!(len);
            println!("{}", pass);
        },
        "dictwords" => {
            let pass = dictwords_password();
            println!("{}", pass);
        },
        m => {
            println!("{} is not a valid mode.", m);
        }
    };
}
