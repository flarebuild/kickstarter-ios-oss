@testable import KsApi
@testable import Library
import Prelude
import ReactiveExtensions
import ReactiveExtensions_TestHelpers
import ReactiveSwift
import XCTest

internal final class CommentsEmptyStateCellViewModelTest: TestCase {
  fileprivate let vm: CommentsEmptyStateCellViewModelType = CommentsEmptyStateCellViewModel()

  fileprivate let backProjectButtonHidden = TestObserver<Bool, Never>()
  fileprivate let goBackToProject = TestObserver<(), Never>()
  fileprivate let goToCommentDialog = TestObserver<Void, Never>()
  fileprivate let goToLoginTout = TestObserver<Void, Never>()
  fileprivate let leaveACommentButtonHidden = TestObserver<Bool, Never>()
  fileprivate let loginButtonHidden = TestObserver<Bool, Never>()
  fileprivate let subtitleIsHidden = TestObserver<Bool, Never>()
  fileprivate let subtitleText = TestObserver<String, Never>()

  fileprivate let creator = User.template
    |> \.name .~ "Fuzzy Wuzzy"
    |> \.id .~ 400

  internal override func setUp() {
    super.setUp()
    self.vm.outputs.backProjectButtonHidden.observe(self.backProjectButtonHidden.observer)
    self.vm.outputs.goBackToProject.observe(self.goBackToProject.observer)
    self.vm.outputs.goToCommentDialog.observe(self.goToCommentDialog.observer)
    self.vm.outputs.goToLoginTout.observe(self.goToLoginTout.observer)
    self.vm.outputs.leaveACommentButtonHidden.observe(self.leaveACommentButtonHidden.observer)
    self.vm.outputs.loginButtonHidden.observe(self.loginButtonHidden.observer)
    self.vm.outputs.subtitleIsHidden.observe(self.subtitleIsHidden.observer)
    self.vm.outputs.subtitleText.observe(self.subtitleText.observer)
  }

  internal func testGoBackToProject() {
    let project = .template
      |> Project.lens.personalization.isBacking .~ false
      |> Project.lens.creator .~ self.creator

    AppEnvironment.login(AccessTokenEnvelope(accessToken: "deadbeef", user: .template))

    self.vm.inputs.configureWith(project: project, update: nil)

    self.backProjectButtonHidden.assertValues([false])

    self.vm.inputs.backProjectTapped()

    self.goBackToProject.assertValueCount(1)
  }

  internal func testGoToCommentDialog() {
    let project = .template
      |> Project.lens.personalization.isBacking .~ true

    AppEnvironment.login(AccessTokenEnvelope(accessToken: "deadbeef", user: .template))

    self.vm.inputs.configureWith(project: project, update: nil)

    self.backProjectButtonHidden.assertValues([true])
    self.goToCommentDialog.assertDidNotEmitValue()
    self.leaveACommentButtonHidden.assertValues([false])
    self.loginButtonHidden.assertValues([true])

    self.vm.inputs.leaveACommentTapped()
    self.goToCommentDialog.assertValueCount(1)
  }

  internal func testGoToLoginTout_LoggedIn_Backer() {
    let project = .template
      |> Project.lens.personalization.isBacking .~ nil

    let projectBacking = .template
      |> Project.lens.personalization.isBacking .~ true

    self.vm.inputs.configureWith(project: project, update: nil)

    self.backProjectButtonHidden.assertValues([true])
    self.goToLoginTout.assertDidNotEmitValue()
    self.leaveACommentButtonHidden.assertValues([true])
    self.loginButtonHidden.assertValues([false])
    self.subtitleIsHidden.assertValues([false])
    self.subtitleText.assertValues([Strings.Log_in_to_leave_a_comment()])

    self.vm.inputs.loginTapped()

    self.goToLoginTout.assertValueCount(1)

    // User logged in and view is reconfigured.
    AppEnvironment.login(AccessTokenEnvelope(accessToken: "deadbeef", user: .template))

    self.vm.inputs.configureWith(project: projectBacking, update: nil)

    self.backProjectButtonHidden.assertValues([true, true])
    self.goToLoginTout.assertValueCount(1)
    self.leaveACommentButtonHidden.assertValues([true, false])
    self.loginButtonHidden.assertValues([false, true])
    self.subtitleIsHidden.assertValues([false, true])
    self.subtitleText.assertValues([Strings.Log_in_to_leave_a_comment()])
  }

  internal func testGoToLoginTout_LoggedIn_NonBacker() {
    let project = .template
      |> Project.lens.personalization.isBacking .~ nil

    let projectBacking = .template
      |> Project.lens.personalization.isBacking .~ false
      |> Project.lens.creator .~ self.creator

    self.vm.inputs.configureWith(project: project, update: nil)

    self.backProjectButtonHidden.assertValues([true])
    self.goToLoginTout.assertDidNotEmitValue()
    self.leaveACommentButtonHidden.assertValues([true])
    self.loginButtonHidden.assertValues([false])
    self.subtitleIsHidden.assertValues([false])
    self.subtitleText.assertValues([Strings.Log_in_to_leave_a_comment()])

    self.vm.inputs.loginTapped()

    self.goToLoginTout.assertValueCount(1)

    // User logged in and view is reconfigured.
    AppEnvironment.login(AccessTokenEnvelope(accessToken: "deadbeef", user: .template))

    self.vm.inputs.configureWith(project: projectBacking, update: nil)

    self.backProjectButtonHidden.assertValues([true, false])
    self.goToLoginTout.assertValueCount(1)
    self.leaveACommentButtonHidden.assertValues([true, true])
    self.loginButtonHidden.assertValues([false, true])
    self.subtitleIsHidden.assertValues([false, false])
    self.subtitleText.assertValues([
      Strings.Log_in_to_leave_a_comment(),
      Strings.Become_a_backer_to_leave_a_comment()
    ])
  }

  internal func testLoggedInNonBacking() {
    let project = .template
      |> Project.lens.personalization.isBacking .~ false
      |> Project.lens.creator .~ self.creator

    AppEnvironment.login(AccessTokenEnvelope(accessToken: "deadbeef", user: .template))

    self.vm.inputs.configureWith(project: project, update: nil)

    self.backProjectButtonHidden.assertValues([false])
    self.leaveACommentButtonHidden.assertValues([true])
    self.loginButtonHidden.assertValues([true])
    self.subtitleIsHidden.assertValues([false])
    self.subtitleText.assertValues([Strings.Become_a_backer_to_leave_a_comment()])
  }

  internal func testLoggedInBackingProject() {
    let project = .template
      |> Project.lens.personalization.isBacking .~ true

    AppEnvironment.login(AccessTokenEnvelope(accessToken: "deadbeef", user: .template))

    self.vm.inputs.configureWith(project: project, update: nil)

    self.backProjectButtonHidden.assertValues([true])
    self.leaveACommentButtonHidden.assertValues([false])
    self.loginButtonHidden.assertValues([true])
    self.subtitleIsHidden.assertValues([true])
    self.subtitleText.assertValueCount(0)
  }

  internal func testLoggedInBackingUpdate() {
    let project = .template
      |> Project.lens.personalization.isBacking .~ true

    AppEnvironment.login(AccessTokenEnvelope(accessToken: "deadbeef", user: .template))

    self.vm.inputs.configureWith(project: project, update: Update.template)

    self.backProjectButtonHidden.assertValues([true])
    self.leaveACommentButtonHidden.assertValues([false])
    self.loginButtonHidden.assertValues([true])
    self.subtitleIsHidden.assertValues([true])
    self.subtitleText.assertValueCount(0)
  }

  internal func testLoggedOut() {
    let project = .template
      |> Project.lens.personalization.isBacking .~ nil

    self.vm.inputs.configureWith(project: project, update: nil)

    self.backProjectButtonHidden.assertValues([true])
    self.leaveACommentButtonHidden.assertValues([true])
    self.loginButtonHidden.assertValues([false])
    self.subtitleIsHidden.assertValues([false])
    self.subtitleText.assertValues([Strings.Log_in_to_leave_a_comment()])
  }

  internal func testLoggedInCreator() {
    let project = .template
      |> Project.lens.personalization.isBacking .~ false
      |> Project.lens.creator .~ self.creator

    AppEnvironment.login(AccessTokenEnvelope(accessToken: "deadbeef", user: self.creator))

    self.vm.inputs.configureWith(project: project, update: nil)

    self.backProjectButtonHidden.assertValues([true])
    self.leaveACommentButtonHidden.assertValues([true])
    self.loginButtonHidden.assertValues([true])
    self.subtitleIsHidden.assertValues([true])
    self.subtitleText.assertValueCount(0)
  }
}
