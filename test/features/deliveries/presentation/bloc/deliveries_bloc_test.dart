import 'package:bloc_test/bloc_test.dart';
import 'package:delivery_express_mobility_frontend/features/deliveries/domain/entities/delivery.dart';
import 'package:delivery_express_mobility_frontend/features/deliveries/domain/usecases/deliveries_usecases.dart';
import 'package:delivery_express_mobility_frontend/features/deliveries/presentation/bloc/deliveries_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateNiceMocks([
  MockSpec<FetchDeliveriesUseCase>(),
  MockSpec<GetDeliveryDetailsUseCase>(),
  MockSpec<UpdateDeliveryStatusUseCase>(),
])
import 'deliveries_bloc_test.mocks.dart';

void main() {
  late DeliveriesBloc deliveriesBloc;
  late MockFetchDeliveriesUseCase mockFetchDeliveriesUseCase;
  late MockGetDeliveryDetailsUseCase mockGetDeliveryDetailsUseCase;
  late MockUpdateDeliveryStatusUseCase mockUpdateDeliveryStatusUseCase;

  final sampleDelivery = Delivery(
    id: '1',
    clientName: 'John Doe',
    clientPhone: '+221771234567',
    pickupAddress: 'A',
    deliveryAddress: 'B',
    status: 'PENDING',
    amount: 5000,
    createdAt: DateTime(2026, 1, 1),
    distance: 10,
    estimatedTime: 30,
  );

  setUp(() {
    mockFetchDeliveriesUseCase = MockFetchDeliveriesUseCase();
    mockGetDeliveryDetailsUseCase = MockGetDeliveryDetailsUseCase();
    mockUpdateDeliveryStatusUseCase = MockUpdateDeliveryStatusUseCase();

    deliveriesBloc = DeliveriesBloc(
      fetchDeliveriesUseCase: mockFetchDeliveriesUseCase,
      getDeliveryDetailsUseCase: mockGetDeliveryDetailsUseCase,
      updateDeliveryStatusUseCase: mockUpdateDeliveryStatusUseCase,
    );
  });

  tearDown(() async {
    await deliveriesBloc.close();
  });

  blocTest<DeliveriesBloc, DeliveriesState>(
    'fetch success -> DeliveriesLoading then DeliveriesLoaded',
    build: () {
      when(mockFetchDeliveriesUseCase.call())
          .thenAnswer((_) async => [sampleDelivery]);
      return deliveriesBloc;
    },
    act: (bloc) => bloc.add(const FetchDeliveriesEvent()),
    expect: () => [
      const DeliveriesLoading(),
      DeliveriesLoaded(deliveries: [sampleDelivery]),
    ],
  );

  blocTest<DeliveriesBloc, DeliveriesState>(
    'details success -> DeliveriesLoading then DeliveryDetailsLoaded',
    build: () {
      when(mockGetDeliveryDetailsUseCase.call('1'))
          .thenAnswer((_) async => sampleDelivery);
      return deliveriesBloc;
    },
    act: (bloc) => bloc.add(const GetDeliveryDetailsEvent(id: '1')),
    expect: () => [
      const DeliveriesLoading(),
      DeliveryDetailsLoaded(delivery: sampleDelivery),
    ],
  );

  blocTest<DeliveriesBloc, DeliveriesState>(
    'update status success -> DeliveryStatusUpdated',
    build: () {
      when(mockUpdateDeliveryStatusUseCase.call('1', 'COMPLETED'))
          .thenAnswer((_) async {});
      return deliveriesBloc;
    },
    act: (bloc) =>
        bloc.add(const UpdateDeliveryStatusEvent(id: '1', status: 'COMPLETED')),
    expect: () => [
      const DeliveryStatusUpdated(deliveryId: '1'),
    ],
  );

  blocTest<DeliveriesBloc, DeliveriesState>(
    'fetch failure -> DeliveriesFailure',
    build: () {
      when(mockFetchDeliveriesUseCase.call())
          .thenThrow(Exception('Network error'));
      return deliveriesBloc;
    },
    act: (bloc) => bloc.add(const FetchDeliveriesEvent()),
    expect: () => [
      const DeliveriesLoading(),
      isA<DeliveriesFailure>(),
    ],
  );
}
