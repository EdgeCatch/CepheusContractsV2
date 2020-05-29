const { program } = require('commander');
const { exec } = require("child_process");
const fs = require("fs");

program
    .version('0.1.0')
    .option('-c, --contracts <path>', 'set contracts dir. defaults to ./contracts')

program
    .command('build [contract]')
    .description('build contracts')
    .option("-o, --output_dir [dir]", "Where store builds", "build")
    .option("-i, --input_dir [dir]", "Where files are located", "contracts")
    .action(function (contract, options) {
        let contractName = contract || "*";
        exec("mkdir -p " + options.output_dir);

        exec(
            `docker run -v $PWD:$PWD --rm -i ligolang/ligo:next compile-contract --michelson-format=json $PWD/${options.input_dir}/${contractName}.ligo main`,
            (err, stdout, stderr) => {
                if (err) throw err;

                fs.writeFileSync(`./${options.output_dir}/${contractName}.json`, stdout);
            }
        );
    });


program.parse(process.argv);