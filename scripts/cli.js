const { program } = require('commander');

program
    .version('0.1.0')
    .option('-c, --contracts <path>', 'set contracts dir. defaults to ./contracts')

program
    .command('build [contract]')
    .description('build contracts')
    .option("-o, --output [dir]", "Where store builds", "build")
    .action(function (contract, options) {
        let contractName = contract || "*";
        console.log(' %s  %s ', contractName, options.output);
    });

program.parse(process.argv);