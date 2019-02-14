import Foundation
import KsApi
import Prelude
import ReactiveSwift
import Result

public protocol PaymentMethodsViewModelInputs {
  func addNewCardSucceeded(with message: String)
  func addNewCardDismissed()
  func didDelete(_ creditCard: GraphUserCreditCard.CreditCard)
  func editButtonTapped()
  func paymentMethodsFooterViewDidTapAddNewCardButton()
  func viewDidLoad()
  func viewWillAppear()
}

public protocol PaymentMethodsViewModelOutputs {
  /// Emits the user's stored cards
  var editButtonIsEnabled: Signal<Bool, NoError> { get }
  var errorLoadingPaymentMethods: Signal<String, NoError> { get }
  var goToAddCardScreen: Signal<Void, NoError> { get }
  var paymentMethods: Signal<[GraphUserCreditCard.CreditCard], NoError> { get }
  var presentBanner: Signal<String, NoError> { get }
  var reloadData: Signal<Void, NoError> { get }
  var showAlert: Signal<String, NoError> { get }
  var tableViewIsEditing: Signal<Bool, NoError> { get }
}

public protocol PaymentMethodsViewModelType {
  var inputs: PaymentMethodsViewModelInputs { get }
  var outputs: PaymentMethodsViewModelOutputs { get }
}

public final class PaymentMethodsViewModel: PaymentMethodsViewModelType,
PaymentMethodsViewModelInputs, PaymentMethodsViewModelOutputs {

  public init() {
    self.reloadData = self.viewDidLoadProperty.signal

    let paymentMethodsEvent = Signal.merge(
      self.viewDidLoadProperty.signal,
      self.addNewCardSucceededProperty.signal.ignoreValues(),
      self.addNewCardDismissedProperty.signal
      )
      .switchMap { _ in
        AppEnvironment.current.apiService.fetchGraphCreditCards(query: UserQueries.storedCards.query)
          .ksr_delay(AppEnvironment.current.apiDelayInterval, on: AppEnvironment.current.scheduler)
          .materialize()
    }

    let deletePaymentMethodEvents = self.didDeleteCreditCardSignal.switchMap { creditCard in
      AppEnvironment.current.apiService.deletePaymentMethod(input: .init(paymentSourceId: creditCard.id))
        .ksr_delay(AppEnvironment.current.apiDelayInterval, on: AppEnvironment.current.scheduler)
        .materialize()
    }

    let deletePaymentMethodEventsErrors = deletePaymentMethodEvents.errors()

    self.showAlert = deletePaymentMethodEventsErrors
      .ignoreValues()
      .map {
        localizedString(
          key: "Something_went_wrong_and_we_were_unable_to_remove_your_payment_method_please_try_again",
          //swiftlint:disable:next line_length
          defaultValue: "Something went wrong and we were unable to remove your payment method, please try again."
        )
    }

    let paymentMethodsValues = paymentMethodsEvent.values().map { $0.me.storedCards.nodes }

    self.errorLoadingPaymentMethods = paymentMethodsEvent.errors().map { $0.localizedDescription }

    self.paymentMethods = Signal.merge(
      paymentMethodsValues,
      paymentMethodsValues.takeWhen(deletePaymentMethodEventsErrors)
    )

    let hasAtLeastOneCard = Signal.merge(
      paymentMethodsValues
        .map { !$0.isEmpty },
      deletePaymentMethodEvents.values()
        .map { $0.totalCount > 0 }
    )

    self.editButtonIsEnabled = Signal.merge(
      self.viewDidLoadProperty.signal.mapConst(false),
      hasAtLeastOneCard
    )

    self.goToAddCardScreen = self.didTapAddCardButtonProperty.signal

    self.presentBanner = self.addNewCardSucceededProperty.signal.skipNil()

    self.tableViewIsEditing = Signal.merge(
      self.editButtonTappedSignal.scan(false) { current, _ in !current },
      self.didTapAddCardButtonProperty.signal.mapConst(false))

    // Koala:
    self.viewWillAppearProperty.signal
      .observeValues { _ in AppEnvironment.current.koala.trackViewedPaymentMethods() }

    deletePaymentMethodEvents.values()
      .ignoreValues()
      .observeValues { _ in AppEnvironment.current.koala.trackDeletedPaymentMethod() }

    deletePaymentMethodEventsErrors
      .ignoreValues()
      .observeValues { _ in AppEnvironment.current.koala.trackDeletePaymentMethodError() }
  }

  fileprivate let (didDeleteCreditCardSignal, didDeleteCreditCardObserver) =
    Signal<GraphUserCreditCard.CreditCard,
    NoError>.pipe()
  public func didDelete(_ creditCard: GraphUserCreditCard.CreditCard) {
    self.didDeleteCreditCardObserver.send(value: creditCard)
  }

  fileprivate let (editButtonTappedSignal, editButtonTappedObserver) = Signal<(), NoError>.pipe()
  public func editButtonTapped() {
    self.editButtonTappedObserver.send(value: ())
  }

  fileprivate let viewDidLoadProperty = MutableProperty(())
  public func viewDidLoad() {
    self.viewDidLoadProperty.value = ()
  }

  fileprivate let viewWillAppearProperty = MutableProperty(())
  public func viewWillAppear() {
    self.viewWillAppearProperty.value = ()
  }

  fileprivate let didTapAddCardButtonProperty = MutableProperty(())
  public func paymentMethodsFooterViewDidTapAddNewCardButton() {
    self.didTapAddCardButtonProperty.value = ()
  }

  fileprivate let addNewCardSucceededProperty = MutableProperty<String?>(nil)
  public func addNewCardSucceeded(with message: String) {
    self.addNewCardSucceededProperty.value = message
  }

  fileprivate let addNewCardDismissedProperty = MutableProperty(())
  public func addNewCardDismissed() {
    self.addNewCardDismissedProperty.value = ()
  }

  public let editButtonIsEnabled: Signal<Bool, NoError>
  public let errorLoadingPaymentMethods: Signal<String, NoError>
  public let goToAddCardScreen: Signal<Void, NoError>
  public let paymentMethods: Signal<[GraphUserCreditCard.CreditCard], NoError>
  public let presentBanner: Signal<String, NoError>
  public let reloadData: Signal<Void, NoError>
  public let showAlert: Signal<String, NoError>
  public let tableViewIsEditing: Signal<Bool, NoError>

  public var inputs: PaymentMethodsViewModelInputs { return self }
  public var outputs: PaymentMethodsViewModelOutputs { return self }
}
