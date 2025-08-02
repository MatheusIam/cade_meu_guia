const fs = require('fs');
const path = require('path');

// Diretório onde o código-fonte do Flutter geralmente reside.
const codigoDir = path.join(__dirname, 'lib');

// Arquivo de saída.
const arquivoSaida = path.join(__dirname, 'codigo_flutter.txt');

// Função para encontrar todos os arquivos .dart recursivamente.
const encontrarArquivosDart = (dir, listaDeArquivos = []) => {
    const arquivos = fs.readdirSync(dir);

    arquivos.forEach(arquivo => {
        const caminhoCompleto = path.join(dir, arquivo);
        if (fs.statSync(caminhoCompleto).isDirectory()) {
            // Se for um diretório, chama a função recursivamente.
            encontrarArquivosDart(caminhoCompleto, listaDeArquivos);
        } else if (path.extname(caminhoCompleto) === '.dart') {
            // Se for um arquivo .dart, adiciona à lista.
            listaDeArquivos.push(caminhoCompleto);
        }
    });

    return listaDeArquivos;
};

try {
    console.log('Iniciando a busca por arquivos .dart...');
    const arquivosDart = encontrarArquivosDart(codigoDir);

    if (arquivosDart.length === 0) {
        console.log('Nenhum arquivo .dart foi encontrado no diretório "lib".');
        return;
    }

    console.log(`Encontrados ${arquivosDart.length} arquivos .dart. Consolidando...`);

    // Prepara o stream de escrita para o arquivo de saída.
    const streamSaida = fs.createWriteStream(arquivoSaida, { encoding: 'utf8' });

    streamSaida.on('finish', () => {
        console.log(`\n✅ Sucesso! O código foi consolidado no arquivo: ${arquivoSaida}`);
    });

    streamSaida.on('error', (err) => {
        console.error('Ocorreu um erro ao escrever no arquivo:', err);
    });

    // Itera sobre cada arquivo, lê seu conteúdo e escreve no stream.
    arquivosDart.forEach((arquivo, index) => {
        const conteudo = fs.readFileSync(arquivo, 'utf8');
        const separador = `\n\n// ---- Início do Arquivo: ${path.relative(__dirname, arquivo)} ----\n\n`;
        
        streamSaida.write(separador);
        streamSaida.write(conteudo);
        
        // Simples indicador de progresso no console.
        process.stdout.write(`\rProcessando arquivo ${index + 1} de ${arquivosDart.length}...`);
    });

    streamSaida.end();

} catch (error) {
    if (error.code === 'ENOENT') {
        console.error(`Erro: O diretório "${codigoDir}" não foi encontrado.`);
        console.error('Por favor, execute este script na pasta raiz do seu projeto Flutter.');
    } else {
        console.error('Ocorreu um erro inesperado:', error);
    }
}