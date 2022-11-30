import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    
    
    
    
    
    
    
    
    private var currentQuestionIndex = 0
    private var questionsAmount = 10
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    private var alertPresenter: AlertPresenterProtocol?
    private var statisticService: StatisticService?
    
    private var countCorrectAnswer = 0
    
    @IBOutlet private weak var imageView: UIImageView!
    
    
    
    @IBOutlet private weak var textLabel: UILabel!
    
    @IBOutlet private weak var counterLabel: UILabel!
    
    @IBOutlet weak var buttonYes: UIButton!
    
    @IBOutlet weak var buttonNo: UIButton!
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else {return}
        let givenAnswer = false
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
        disableMyButtons()
    }
    
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else {return}
        let givenAnswer = true
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
        disableMyButtons()
    }
    // MARK: - Lifecycle
    
    private func disableMyButtons() {
        buttonNo.isEnabled = false
        buttonYes.isEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.buttonNo.isEnabled = true
            self.buttonYes.isEnabled = true
        }
        
        
    }
    
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        return QuizStepViewModel (image: UIImage(named: model.image) ?? UIImage(),
                                  question: model.text,
                                  questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
        
    }
    
    
    private func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    private func showAnswerResult(isCorrect: Bool) {
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 20
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        
        if isCorrect{
            countCorrectAnswer += 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.showNextQuestionOrResults()
            self.imageView.layer.borderWidth = 0
            
            
        }
    }
    
    
    private func completion() {
        imageView.layer.cornerRadius = 20
        currentQuestionIndex = 0
        countCorrectAnswer = 0
        questionFactory?.requestNextQuestion()
    }
    private func convertAlertModel(model: QuizResultsViewModel) -> AlertModel {
            return AlertModel(title: model.title,
                              message: model.text,
                              buttonText: model.buttonText,
                              completion: completion)
        }
//    private func convertGameRecord(model: GameRecord) -> String {
//        return
//    }

    private func showNextQuestionOrResults() {
        let alertModel = QuizResultsViewModel(title: "Этот раунд окончен!",
                                              text: """
                                               Ваш результат: \(countCorrectAnswer)/10
                                               Количество завершённых квизов: \(String(describing: statisticService!.gamesCount))
                                               Рекорд: \(String(describing: statisticService!.bestGame.correct))/\(String(describing: statisticService!.bestGame.total)) (\(String(describing: statisticService!.bestGame.date))
                                               Средняя точность: \(String(format: "%.2f", statisticService!.totalAccuracy))%
                                               """,
                                              buttonText: "Сыграть еще раз!")
        let modelResult = convertAlertModel(model: alertModel)
        guard let setNewValue = statisticService?.gamesCount else {return }
        
        if currentQuestionIndex == questionsAmount - 1 {
           
            alertPresenter?.show(quiz: modelResult)
            setNewGameCount(with: setNewValue + 1)
            setStoreGameResult(correctAnswersNumber: countCorrectAnswer, totalQuestionsNumber: questionsAmount)
            setStoreRecord(correct: countCorrectAnswer , total: questionsAmount)
            
        } else {
            currentQuestionIndex += 1
            questionFactory?.requestNextQuestion()
        }
    }
    
    func setStoreRecord(correct count: Int, total amount: Int) {
        statisticService?.storeRecord(correct: count, total: amount)
    }
    
    
    func setNewGameCount(with gameCount: Int) {
        statisticService?.setGameCount(gamesCount: gameCount)
        }
    
    func setStoreGameResult(correctAnswersNumber: Int, totalQuestionsNumber: Int) {
        
            statisticService?.storeGameResult(correctAnswersNumber: correctAnswersNumber , totalQuestionsNumber: totalQuestionsNumber)
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        questionFactory = QuestionFactory(delegate: self)
        questionFactory?.requestNextQuestion()
        alertPresenter = AlertPresenter(controller: self)
        statisticService = StatisticServiceImplementation()
        

        func string(from documentDirectory: URL) throws -> String {
            if !FileManager.default.fileExists(atPath: documentDirectory.path) {
                throw FileManagerError.fileDoesntExist
            }
            return try String(contentsOf: documentDirectory)
        }

//        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//        let fileURL = documentDirectory.appendingPathComponent("top250MoviesIMDB.json")
//        let top250MoviesIMDB = try! string(from: fileURL)
//        guard let data = top250MoviesIMDB.data(using: .utf8) else {return}
//        do {
//            let movie = try JSONDecoder().decode(Movie.self, from: data)
//            let result = try? JSONDecoder().decode(Top.self, from: data)
//        } catch {
//            print("Failed to parse: \(error.localizedDescription)")
//
//        }
        
        
        enum FileManagerError: Error {
            case fileDoesntExist
        }
    }
    // MARK: - QuestionFactoryDelegate
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
    
    

}




struct Result {
    let answer: Bool
}



