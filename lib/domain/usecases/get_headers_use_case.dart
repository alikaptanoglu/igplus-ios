import 'package:dartz/dartz.dart';
import 'package:igplus_ios/data/failure.dart';
import 'package:igplus_ios/domain/entities/ig_headers.dart';
import 'package:igplus_ios/domain/repositories/firebase/headers_repository.dart';

import '../entities/user.dart';

class GetHeadersUseCase {
  final HeadersRepository headersRepository;

  GetHeadersUseCase({required this.headersRepository});
  Future<Either<Failure, IgHeaders>> execute({User? currentUser, Map<String, dynamic>? headers}) async {
    return await headersRepository.getHeaders(currentUser: currentUser, headers: headers);
  }
}
