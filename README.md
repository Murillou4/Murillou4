# Plataforma de Correção Automática de Provas

## Visão Geral

Sistema avançado de correção automática de provas objetivas que combina um backend .NET 10+ com aplicativo móvel Flutter e processamento de visão computacional OpenCV. A plataforma oferece funcionalidade offline-first com segurança baseada em QR codes assinados digitalmente.

## Arquitetura do Sistema

### Pilares Fundamentais

- **Segurança por Design**: QR codes assinados digitalmente com JWT
- **Resiliência Offline-First**: Funcionalidade completa sem internet
- **Reconhecimento de Alta Fidelidade**: Pipeline OpenCV otimizado para OMR
- **Escalabilidade**: Arquitetura modular preparada para expansões futuras

### Estrutura do Projeto

```
/
├── backend/           # API .NET 10+ para geração de materiais
├── mobile_app/        # Aplicativo Flutter para correção
├── docs/             # Documentação técnica
└── README.md         # Este arquivo
```

## Backend (.NET 10+)

### Funcionalidades Principais

- **AssessmentService**: Gerenciamento de avaliações
- **QrCodeService**: Geração de QR codes seguros
- **SecurityService**: Operações criptográficas (JWT/RS256)
- **Minimal APIs**: Endpoints otimizados para performance

### Tecnologias Utilizadas

- .NET 10 (LTS)
- System.IdentityModel.Tokens.Jwt
- Net.Codecrete.QrCodeGenerator
- Minimal API pattern

## Mobile App (Flutter)

### Funcionalidades Principais

- **Escaneamento de QR Code**: Validação criptográfica offline
- **Processamento OMR**: Pipeline OpenCV para detecção de marcas
- **Armazenamento Local**: Banco Hive para persistência offline
- **Exportação Excel**: Relatórios profissionais com Syncfusion

### Bibliotecas Principais

- `mobile_scanner`: Escaneamento de QR codes
- `hive_ce`: Banco de dados local
- `syncfusion_flutter_xlsio`: Geração de Excel
- `share_plus`: Compartilhamento de arquivos
- OpenCV via FFI: Processamento de imagem

## Fluxo de Trabalho

1. **Geração**: Professor cria avaliação no backend
2. **Impressão**: Folha OMR com QR code seguro é impressa
3. **Escaneamento**: App móvel lê QR code e valida assinatura
4. **Correção**: Pipeline OpenCV processa marcações
5. **Resultados**: Notas calculadas e armazenadas localmente
6. **Exportação**: Relatórios Excel profissionais gerados

## Segurança

- **JWT RS256**: Assinatura assimétrica para QR codes
- **Validação Offline**: Chave pública embarcada no app
- **Integridade**: Detecção de adulteração de dados
- **Isolamento**: Chaves privadas protegidas no backend

## Requisitos do Sistema

### Backend
- .NET 10+ SDK
- Windows/Linux/macOS

### Mobile App
- Flutter 3.x
- Android 8+ / iOS 12+
- Câmera com foco automático

## Instalação e Execução

### Backend

```bash
cd backend
dotnet restore
dotnet run
```

### Mobile App

```bash
cd mobile_app
flutter pub get
flutter run
```

## Roadmap Futuro

- [ ] Sincronização em nuvem
- [ ] Painel web para análises
- [ ] Análise de itens e estatísticas
- [ ] Integração com sistemas acadêmicos
- [ ] Suporte a múltiplos idiomas

## Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## Licença

Este projeto está licenciado sob a MIT License - veja o arquivo LICENSE para detalhes.

## Contato

Para dúvidas técnicas ou suporte, abra uma issue no repositório.
