# Otimizador do Windows

O **Otimizador do Windows** é uma ferramenta modular criada por **Elberth Mayan** para transformar a experiência pós-formatação e melhorar a performance do sistema no dia a dia. Em vez de perder horas configurando manualmente cada detalhe, este script automatiza a remoção de bloatwares, ajustes de telemetria, otimização de serviços e muito mais.

## 🚀 Como usar (Execução Rápida)

Para rodar o otimizador instantaneamente sem precisar baixar nada, abra o **PowerShell como Administrador** e cole o comando abaixo:

```powershell
iex (irm https://raw.githubusercontent.com/elberthmayan/Otimizar_Windows/main/win-debloater.ps1)
```

## 🛠️ Instalação Local (Clonagem)

Se preferir baixar o projeto completo para o seu computador:

1.  Abra o terminal e clone o repositório:
    ```bash
    git clone https://github.com/elberthmayan/Otimizar_Windows.git
    ```
2.  Entre na pasta do projeto:
    ```bash
    cd Otimizar_Windows
    ```
3.  Execute o arquivo `run_test.bat` como **Administrador**.

## ✨ Funcionalidades (v3.0)

A ferramenta oferece um menu interativo com as seguintes opções:

1.  **Remover Bloatware:** Faxina completa de aplicativos inúteis que vêm pré-instalados.
2.  **Configurações Iniciais:** Otimiza funções de jogos, desativa IA e instala navegadores.
3.  **Desinstalar OneDrive:** Remove completamente o OneDrive do sistema.
4.  **Bloquear Avisos:** Desativa avisos de upgrade para Windows 11 e conta Microsoft.
5.  **Limpeza de Sistema:** Limpa cache e arquivos temporários.
6.  **Desativar Telemetria:** Bloqueia o rastreamento da Microsoft.
7.  **ativar windows / office:** Scripts de ativação integrados.
8.  **Ferramenta Personalizada:** Abre o executável complementar (pasta `Progama`).
9.  **Ajustar Efeitos Visuais:** Foca em "Melhor Desempenho".
10. **Otimizar Serviços:** Ajusta serviços de fundo (SysMain, Spooler, etc).
11. **Atualizar Drivers:** Instala drivers recentes via `winget`.
12. **Executar otimizacao automaticamente:** Roda as principais tarefas de uma vez.
13. **REVERTER ALTERACOES:** Restaura o sistema para um ponto anterior.
14. **Sair:** Fecha a ferramenta com segurança.

## ⚠️ Recomendações
- Aceite a criação do **Ponto de Restauração** quando solicitado pelo script.
- Recomendado para máquinas recém-formatadas ou para quem busca performance máxima.

---
**Criado por: Elberth Mayan**  
[GitHub](https://github.com/elberthmayan) | [Repositório do Projeto](https://github.com/elberthmayan/Otimizar_Windows)
