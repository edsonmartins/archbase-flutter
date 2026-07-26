/// Porta de upload de binários (fotos/assinaturas) do módulo `archbase_offline`.
///
/// Binários sobem por multipart em canal separado do JSON. O motor usa esta porta
/// para o gating: a entidade só vira `sincronizado` quando os binários dela subiram.
library;

/// Resultado do upload de um binário.
class ArchbaseBinaryUploadResult {
  const ArchbaseBinaryUploadResult({required this.remoteId, this.remoteUrl});
  final String remoteId;
  final String? remoteUrl;
}

/// Binário anexado a uma operação de sync (foto/assinatura pendente de upload).
/// Enquanto houver binário não enviado, a entidade não atinge `sincronizado`.
class ArchbaseOpBinary {
  const ArchbaseOpBinary({
    required this.localPath,
    required this.category,
    this.remoteId,
    this.meta,
  });

  final String localPath;
  final String category;

  /// Preenchido após o upload; `null` = ainda pendente.
  final String? remoteId;
  final Map<String, dynamic>? meta;

  bool get isUploaded => remoteId != null;

  ArchbaseOpBinary copyWith({String? remoteId}) => ArchbaseOpBinary(
        localPath: localPath,
        category: category,
        remoteId: remoteId ?? this.remoteId,
        meta: meta,
      );
}

/// Porta de upload. A impl do app reusa o `StorageRepository`/multipart existente.
abstract interface class ArchbaseBinaryUploader {
  /// Sobe o arquivo em [localPath] e devolve o id remoto. Deve lançar em falha
  /// (o motor mantém o gating pendente e tenta de novo no próximo ciclo).
  Future<ArchbaseBinaryUploadResult> upload({
    required String localPath,
    required String category,
    Map<String, dynamic>? meta,
  });
}
