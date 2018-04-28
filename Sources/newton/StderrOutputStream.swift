
import Foundation


final class StderrOutputStream: TextOutputStream {
    func write(_ string: String) {
        fputs(string, stderr)
    }
}

let errStream = StderrOutputStream()
